defmodule Syncex.UpdateWorker do
  use GenServer
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
    GenServer.call(server, {:update, change})
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

  def handle_call({:update, change}, _from, state) do
    country = country(change.meta.routing_key)
    Logger.debug "#{country}(#{change.meta.type}): Upserting #{inspect change.location["uuid"]}"
    location_uuid = change.location["uuid"]
    :ok = {location_uuid, country, change.location["api_url"]}
    |> LocationService.fetch_location
    |> RabbitHelper.add_metadata(change)
    |> CouchHelper.update_location
    |> RabbitHelper.dispatch_synchronized_event(change, state, country)
    Logger.info "Completed #{inspect location_uuid} - #{address(change.location)}"
    {:reply, set_latest_synced(state, change), state}
  end

  defp address(location) do
    "#{location["address_line_1"] || location["address_line1"]}, #{location["postal_code"]} #{location["postal_name"]}"
  end

  defp set_latest_synced(state, event_doc) do
    state |> Map.put(:latest_synced_event, event_doc)
  end

  defp country(routing_key) do
    [_, country, _type, _event] = Regex.run(~r/(.*)\.(.*)\.(.*)/, routing_key)
    country
  end

end
