defmodule Syncex do
  use Application

  @update_worker Syncex.UpdateWorker
  @sequence Syncex.Sequence.Server
  @location_service LocationService

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Dotenv.load!

    children = [
      worker(GenServer, [@update_worker, %{sequence: @sequence}, [name: @update_worker]]),
      worker(Syncex.Sequence.Server, [@sequence]),
      worker(Syncex.ChangeListener, [{@update_worker, @sequence}])
    ]

    opts = [strategy: :one_for_one, name: Syncex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
