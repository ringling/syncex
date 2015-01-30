defmodule Syncex.Sequence.Server do
  use GenServer

  #####
  # External API
  def start_link do
    last_seq = fetch_latest_sequence_number
    GenServer.start_link(__MODULE__, last_seq)
  end

  def start_link(seq_number) when is_number(seq_number) do
    last_seq = 0
    GenServer.start_link(__MODULE__, last_seq)
  end

  def start_link(name) do
    last_seq = fetch_latest_sequence_number
    GenServer.start_link(__MODULE__, last_seq, name: name)
  end

  def set_sequence(seq_number), do: set_sequence(__MODULE__, seq_number)
  def set_sequence(server, seq_number) do
    GenServer.call(server, {:set_sequence, seq_number})
  end

  def get_sequence, do: get_sequence(__MODULE__)
  def get_sequence(server) do
    GenServer.call(server, {:get_sequence})
  end

  def force_set_sequence(seq_number), do: force_set_sequence(__MODULE__, seq_number)
  def force_set_sequence(server, seq_number) do
    GenServer.call(server, {:force_set_sequence, seq_number})
  end

  defp fetch_latest_sequence_number do
    LocationService.max_sequence_number
  end

  #####
  # GenServer implementation
  def handle_call({ :get_sequence }, _from, current_seq) do
    { :reply, current_seq, current_seq }
  end

  def handle_call({ :set_sequence, new_seq_number }, _from, current_seq) do
    validate(current_seq, new_seq_number) |> reply(current_seq)
  end

  def handle_call({ :force_set_sequence, new_seq_number }, _from, _) do
     { :reply, {:ok, new_seq_number }, new_seq_number }
  end

  defp reply({:ok, new_seq_number}, _), do: { :reply, {:ok, new_seq_number }, new_seq_number }
  defp reply({:error, msg, seq_number} = err_msg, current_seq), do: { :reply, err_msg, current_seq }

  defp validate(current_seq, new_seq_number) when new_seq_number==current_seq + 1  do
    {:ok, new_seq_number }
  end

  defp validate(current_seq, failed_seq_number) do
    {:error, "Sequence error: #{current_seq}!=#{failed_seq_number}+1", failed_seq_number }
  end

end
