defmodule Syncex.UpdateWorker do
  use GenServer
  use Timex
  import CouchHelper
  require Logger

  ## Client API

  def start_link(state) do
    GenServer.start_link(__MODULE__,[state])
  end

  def latest_synced_event, do: latest_synced_event(__MODULE__)
  def latest_synced_event(server) do
    GenServer.call(server, :latest_synced_event)
  end

  def update(change), do: update(__MODULE__, change)
  def update(server, change) do
    GenServer.cast(server, {:update, change})
  end

  ## Server Callbacks

  def init(state) do
    Logger.info "UpdateWorker started"
    state = state
      |> Map.put(:latest_synced_event, nil)
      |> Map.put(:channel, RabbitHelper.open_channel)
    {:ok, state}
  end

  def handle_call(:latest_synced_event, _from, state) do
    {:reply, state.latest_synced_event, state}
  end

  def handle_cast({:update, change }, state) do
    country = country(change.meta.routing_key)

    Logger.debug "#{country}(#{change.meta.type}): Upserting #{inspect change.location["uuid"]}"
    location_uuid = change.location["uuid"]
    :ok = {location_uuid, country}
    |> LocationService.fetch_location
    |> add_metadata(change)
    |> update_location
    |> dispatch_synchronized_event(change, state, country)
    Logger.info "Completed #{inspect location_uuid} - #{change.location["address_line1"]}"
    { :noreply, set_latest_synced(state, change) }
  end

  defp set_latest_synced(state, event_doc) do
    state |> Map.put(:latest_synced_event, event_doc)
  end

  defp update_location({:error, err_message }), do: {:error, err_message }
  defp update_location({location, country}), do:  execute_post({location, country})

  defp dispatch_synchronized_event({:ok, _}, change, state, country) do
    json_msg = change.location |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    type = "location.synchronized"
    routing_key = "#{country}.#{type}"
    AMQP.Basic.publish(state.channel, exchange, routing_key, json_msg, opts(type))
  end

  defp dispatch_synchronized_event({:error, error}, change, state, country) do
    json_msg = %{change: change, error: error} |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    type = "location.synchronize_failed"
    routing_key = "#{country}.#{type}"
    AMQP.Basic.publish(state.channel, exchange, routing_key, json_msg, opts(type))
  end

  defp app_id, do: "syncex"
  defp opts(type), do: [persistent: true, type: type, app_id: app_id, content_type: "application/json"]

  defp exchange, do: System.get_env("RABBITMQ_EXCHANGE") || "lb"

  defp add_metadata({ :error, err_message }, _), do: {:error, err_message }
  defp add_metadata({ :ok, location }, change)    do
    metadata = %{
      type: change.meta.type,
      message_id: change.meta.message_id,
      timestamp: change.meta.timestamp,
      updated_date: DateFormat.format!(Date.local, "{ISO}")
    }

    location = location |> Map.put(:metadata, metadata)
    {location, country(change.meta.routing_key)}
  end

  defp country(routing_key) do
    [_, country, _type, _event] = Regex.run(~r/(.*)\.(.*)\.(.*)/, routing_key)
    country
  end

end
