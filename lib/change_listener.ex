defmodule Syncex.ChangeListener do
 use GenServer
 require Logger

  @one_minute 60000
  ## Client API

  @doc """
  Starts ChangeListener.
  """
  def start_link(name, state) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  ## Server Callbacks

  def init({worker, sequence}) do
    state = %{worker: worker, sequence: sequence}
    # TODO This has to be done more cleverly
    spawn_link(Syncex.ChangeListener, :listen, [state])
    Logger.info "ChangeListener started - start seq #{last_seq(state.sequence)}"
    {:ok, state}
  end

  def init(:ok, state), do: {:ok, state}

  def listen(state) do
    last_seq = last_seq(state.sequence)
    { :ok, stream_ref } =
      CouchHelper.event_db
      |> Couchex.follow([:continuous, :heartbeat, {:since, last_seq}, {:include_docs, true}])
    listen(stream_ref, state)
  end

  def listen(stream_ref, state) do
    receive do
      {_stream_ref, {:done, l_seq}} ->
        Logger.info "stopped, last seq is #{inspect l_seq}"
        :ok
      {_stream_ref, {:change, change}} ->
        handle_change(state, change)
        listen(stream_ref, state)
      {_stream_ref, error}->
        Logger.error "Error: #{inspect error}"
        wait(@one_minute)
        listen(stream_ref, state)
      msg ->
        Logger.warn "Unknown msg: #{inspect msg}"
        wait(@one_minute)
        listen(stream_ref, state)
    end
  end

  defp wait(ms), do: :timer.sleep(ms)

  defp last_seq(sequence_server) do
    Syncex.Sequence.Server.get_sequence(sequence_server)
  end

  defp handle_change(state, change) do
    { seq, doc } = change |> Syncex.Event.doc

    case Syncex.Event.from_doc(doc) do
      {:error, :no_match} ->
        Logger.error "Couldn't match doc: #{inspect doc}"
      doc ->
        state.worker
          |> Syncex.UpdateWorker.update(doc, seq)
    end

  end

end
