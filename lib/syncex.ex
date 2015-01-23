defmodule Syncex do
  use Application

  @update_worker Syncex.UpdateWorker
  @sequence Syncex.Sequence.Server
  @area Syncex.Area.Server
  @location_service LocationService
  @error_stack Syncex.ErrorStack
  @change_listener Syncex.ChangeListener

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Dotenv.load!

    ten_minutes = 60*1000*10

    children = [
      worker(Syncex.ErrorStack, [@error_stack]),
      worker(Syncex.DmsNotifier, [ten_minutes]),
      worker(Syncex.Area.Server, [@area]),
      worker(GenServer, [@update_worker, %{sequence: @sequence}, [name: @update_worker]]),
      worker(Syncex.Sequence.Server, [@sequence]),
      worker(Syncex.ChangeListener, [@change_listener, {@update_worker, @sequence}])
    ]

    opts = [strategy: :one_for_one, name: Syncex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
