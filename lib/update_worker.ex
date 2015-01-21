defmodule Syncex.UpdateWorker do
  use GenServer
  use Timex
  import CouchHelper
  require Logger

  ## Client API

  def start_link(state) do
    GenServer.start_link(__MODULE__,[state])
  end

  def update(doc, seq_number), do: update(__MODULE__, doc, seq_number)
  def update(server, doc, seq_number) do
    GenServer.cast(server, {:update, {doc, seq_number}})
  end

  ## Server Callbacks

  def init(state) do
    Logger.info "UpdateWorker started"
    {:ok, state}
  end

  def handle_cast({:update, {event_doc, seq_number} }, state) do
    Logger.debug "#{event_doc.country}: Upserting #{inspect event_doc.location_uuid} - seq: #{seq_number} - evt_date: #{event_doc.created_at}"
    {event_doc.location_uuid, event_doc.country}
      |> LocationService.fetch_location
      |> add_metadata(event_doc, seq_number)
      |> update_location
      |> update_sequence(seq_number, state)

    Logger.info "Completed #{inspect event_doc.location_uuid} - seq #{seq_number}"
    { :noreply, state }
  end

  defp update_location({:error, err_message }), do: {:error, err_message }
  defp update_location(loc_doc), do:  execute_post(loc_doc)

  defp add_metadata({ :error, err_message }, _, _), do: {:error, err_message }
  defp add_metadata({ :ok, location }, event_doc,  seq_number) do
    Logger.debug "'#{location["address_line1"]}, #{location["postal_code"]} #{location["postal_name"]}' -> #{location["_links"]["self"]["href"]}"
    metadata = %{
      type: "location_event_metadata",
      seq_number: seq_number,
      event_uuid: event_doc.id,
      event_date: event_doc.created_at,
      updated_date: DateFormat.format!(Date.local, "{ISO}")
    }

    location = location
      |> Map.put(:metadata, metadata)

    { location, event_doc }
  end

  defp update_sequence({ :ok, _status }, seq_number, state) do
    state.sequence
      |> Syncex.Sequence.Server.set_sequence(seq_number)
    	|> handle_sequence_response(state)
  end

  defp update_sequence({:error, msg}, seq_number, state) do
    # Add location to error queue
    Logger.error("Error during update: '#{msg}' - #{seq_number}")
    state.sequence
      |> Syncex.Sequence.Server.set_sequence(seq_number)
      |> handle_sequence_response(state)
  end

  defp handle_sequence_response({:ok, updated_seq_number }, _state), do: updated_seq_number
  defp handle_sequence_response({:error, err_msg, failed_seq_number }, state) do
    # TODO: Notify somebody about sequence_error and force set
    Logger.error(err_msg)
    state.sequence
      |> Syncex.Sequence.Server.force_set_sequence(failed_seq_number)
  end

end
