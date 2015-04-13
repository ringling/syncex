defmodule Syncex.Status do
  use GenServer
  require Logger

  ## Client API

  @name {:global,__MODULE__}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def in_sync?(service \\ %{sequence_server: Syncex.Sequence.Server, location_service: LocationService}) do
    GenServer.call(@name, {:in_sync?, service})
  end

  def latest_synced_event(update_worker \\ Syncex.UpdateWorker) do
    GenServer.call(@name, {:latest_synced_event, update_worker})
  end


  ## Server Callbacks

  def init(:ok) do
    Logger.info "Status started"
    {:ok, []}
  end

  def handle_call({:in_sync?, service}, _from, state) do
    reply = current_seq(service.sequence_server) == max_seq(service.location_service)
    {:reply, reply, state}
  end


  def handle_call({:latest_synced_event, update_worker}, _from, state) do
    {:reply, update_worker.latest_synced_event, state}
  end

  defp current_seq(sequence_server), do: sequence_server.get_sequence

  defp max_seq(location_service), do: location_service.max_sequence_number


end
