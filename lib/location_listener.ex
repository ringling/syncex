defmodule Syncex.LocationListener do
  use GenServer
  use AMQP
  require Logger

  def start_link(state) do
    Logger.info "Starting LocationListener - state #{inspect state}"
    GenServer.start_link(__MODULE__, state)
  end

  def start_link(state, [name: name]) do
    Logger.info "Starting LocationListener with name #{name} - state #{inspect state}"
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def location_event(location, meta),         do: location_event(__MODULE__, location, meta)
  def location_event(server, location, meta), do: GenServer.call(server, {:location_event, location, meta})

   ## Server Callbacks
  def init(state) do
    {:ok, conn} = Connection.open(rabbit_mq_url)
    {:ok, chan} = Channel.open(conn)

    AMQP.Queue.declare(chan, state.queue)
    AMQP.Exchange.declare(chan, state.exchange, :topic, [auto_delete: false, durable: true])
    AMQP.Queue.bind(chan, state.queue, state.exchange, [routing_key: state.routing_key])
    AMQP.Queue.subscribe(chan, state.queue, fn(payload, meta) ->
      location = payload |> Poison.decode!
      Syncex.LocationListener.location_event(location, meta)
    end)

    {:ok, state}
  end

  def handle_call({:location_event, location, meta}, _from, state) do
    change = %{location: location, meta: meta}
    resp = handle_change(state, change, Application.get_env(:syncex, :environment))
    {:reply, resp, state}
  end

  defp handle_change(state, change, :test) do
    Logger.info "Rabbit Location Event received -> #{inspect change.meta.routing_key}"
    Logger.debug inspect "#{change.location["address_line1"]}, #{ change.location["postal_code"]} #{ change.location["postal_name"]}"
    Logger.debug inspect change.location["uuid"]
    :ok
  end

  defp handle_change(state, change, _) do
    state.worker |> Syncex.UpdateWorker.update(change)
  end

  defp rabbit_mq_url, do: System.get_env("RABBITMQ_URL")

end
