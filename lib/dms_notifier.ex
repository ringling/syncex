defmodule Syncex.DmsNotifier do
  use GenServer
  require Logger

  def start_link(interval_ms) do
    GenServer.start_link(__MODULE__, interval_ms, [])
  end

  def init(interval_ms) do
    dms_url = System.get_env("DEADMANS_SNITCH_URL")
    notify(dms_url)
    notifier_pid = spawn_link(Syncex.DmsNotifier, :loop, [dms_url, 0])
    start_timer({interval_ms, notifier_pid})
    {:ok, interval_ms}
  end

  def start_timer({interval_ms, notifier_pid}) do
    :timer.send_interval(interval_ms, notifier_pid, {self, :notify })
    Logger.info "DmsNotifier Timer started - interval_ms #{interval_ms}"
  end

  def loop(dms_url, count) do
    receive do
      {_sender, :notify} ->
        notify(dms_url)

      {_sender, msg} ->
        Logger.error msg
    end
    loop(dms_url, count+1)
  end

  def notify(dms_url) do
    case HTTPotion.get(dms_url,[]) do
      %HTTPotion.Response{status_code: 202, body: _} ->
        Logger.debug "DMS notified - #{dms_url}"
      %HTTPotion.Response{status_code: sc, body: body} ->
        Logger.error "DMS error(#{sc}) -> #{dms_url} -> body #{inspect body}"
    end
  end

end
