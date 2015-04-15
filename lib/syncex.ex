defmodule Syncex do
  use Application

  @update_worker Syncex.UpdateWorker
  @sequence Syncex.Sequence.Server
  @area Syncex.Area.Server
  @location_service LocationService

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Dotenv.load!

    ten_minutes = 60*1000*10

    children = [
      worker(Syncex.DmsNotifier, [ten_minutes]),
      worker(Syncex.Area.Server, [@area]),
      worker(GenServer, [@update_worker, %{sequence: @sequence}, [name: @update_worker]]),
      worker(Syncex.Sequence.Server, [@sequence]),
      worker(Syncex.Status, [])
    ]

    opts = [strategy: :one_for_one, name: Syncex.Supervisor, max_restarts: 1000, max_seconds: 10]
    Supervisor.start_link(children, opts)
  end
end
