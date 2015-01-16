defmodule ErrbitBackend do
  use GenEvent

  def init({__MODULE__, name}) do
    {:ok, []}
  end

  def handle_event(event, parent) do
    # {:info, #PID<0.23.0>,
    #  {Logger, "INFO", {{2015, 1, 15}, {20, 37, 56, 335}},
    #   [pid: #PID<0.247.0>, module: LoggerFileBackendTest,
    #    function: {:"test the truth", 1}, line: 7]}}
    # TODO call http://github.com/kenpratt/erlbrake
    {:ok, parent}
  end

end
