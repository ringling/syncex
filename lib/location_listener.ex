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
    {:ok, location} = decode_location(change)
    location = location |> Syncex.LocationSanitizer.sanitize
    Logger.info "Location Event received(#{location["type"]}) -> #{inspect change.meta.routing_key}"
    Logger.debug inspect "#{location["address_line1"]}, #{ location["postal_code"]} #{ location["postal_name"]}"
    Logger.debug inspect location["uuid"]
    :ok
  end
  defp handle_change(true, worker, change, _) do
    call_worker(decode_location(change), worker, change)
  end
  defp handle_change(false, _, change, _), do: Logger.debug "Ignoring event #{inspect change.meta.type}"

  defp call_worker({:error, error}, _, _change) do
    Logger.error("Event decoding error: #{inspect error}")
  end
  defp call_worker({:ok, location}, worker, change) do
    worker |> Syncex.UpdateWorker.update(%{location: location, meta: change.meta})
  end

  defp env, do: Application.get_env(:syncex, :environment)

  defp subscribe_to_mq_events(state) do
    chan = RabbitHelper.open_channel
    AMQP.Queue.declare(chan, state.queue)
    state.routing_keys |> Enum.each(fn(routing_key)->
      AMQP.Queue.bind(chan, state.queue, state.exchange, [routing_key: routing_key])
    end)
    AMQP.Queue.subscribe(chan, state.queue, fn(payload, meta) ->
      Syncex.LocationListener.location_event(payload, meta)
    end)
  end

  defp decode_location(change), do: change.payload |> Poison.decode

end
