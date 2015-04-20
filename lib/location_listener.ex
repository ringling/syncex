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

  def location_event(payload, meta),         do: location_event(__MODULE__, payload, meta)
  def location_event(server, payload, meta), do: GenServer.call(server, {:location_event, %{payload: payload, meta: meta}})

   ## Server Callbacks
  def init(state) do
    subscribe_to_mq_events(state)
    {:ok, state}
  end

  def handle_call({:location_event, change}, _from, state) do
    resp = change.meta.type |> Syncex.Event.is_valid_event? |> handle_change(state.worker, change, env)
    {:reply, resp, state}
  end

  defp handle_change(true, _, change, :test) do
    location = location(change)
    Logger.info "Rabbit Location Event received -> #{inspect change.meta.routing_key}"
    Logger.debug inspect "#{location["address_line1"]}, #{ location["postal_code"]} #{ location["postal_name"]}"
    Logger.debug inspect location["uuid"]
    :ok
  end
  defp handle_change(true, worker, change, _) do
    location = location(change)
    worker |> Syncex.UpdateWorker.update(%{location: location, meta: change.meta})
  end
  defp handle_change(false, _, change, _), do: Logger.debug "Ignoring event #{inspect change.meta.type}"

  defp env, do: Application.get_env(:syncex, :environment)

  defp rabbit_mq_url, do: System.get_env("RABBITMQ_URL")

  defp subscribe_to_mq_events(state) do
    {:ok, conn} = Connection.open(rabbit_mq_url)
    {:ok, chan} = Channel.open(conn)

    AMQP.Queue.declare(chan, state.queue)
    AMQP.Exchange.declare(chan, state.exchange, :topic, [auto_delete: false, durable: true])
    AMQP.Queue.bind(chan, state.queue, state.exchange, [routing_key: state.routing_key])
    AMQP.Queue.subscribe(chan, state.queue, fn(payload, meta) ->
      Syncex.LocationListener.location_event(payload, meta)
    end)
  end

  defp location(change), do: change.payload |> Poison.decode!

end
