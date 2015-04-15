defmodule Syncex do
  use Application

  @update_worker Syncex.UpdateWorker
  @sequence Syncex.Sequence.Server
  @area Syncex.Area.Server
  @location_service LocationService
  @location_listener Syncex.LocationListener
  @ten_minutes 60*1000*10

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Dotenv.load!


    location_listener_state = %{exchange: exchange, queue: queue, routing_key: routing_key, worker: @update_worker}

    children = [
      worker(Syncex.DmsNotifier, [@ten_minutes]),
      worker(Syncex.Area.Server, [@area]),
      worker(GenServer, [@update_worker, %{sequence: @sequence}, [name: @update_worker]]),
      worker(Syncex.Sequence.Server, [@sequence]),
      worker(Syncex.LocationListener, [location_listener_state, [name: @location_listener]]),
      worker(Syncex.Status, [])
    ]

    opts = [strategy: :one_for_one, name: Syncex.Supervisor, max_restarts: 1000, max_seconds: 10]
    Supervisor.start_link(children, opts)
  end

  defp routing_key, do: System.get_env("RABBITMQ_LOCATIONS_ROUTING_KEY") || "*.location.*"

  defp exchange, do: System.get_env("RABBITMQ_EXCHANGE") || "lb"

  defp queue, do: System.get_env("RABBITMQ_QUEUE") || "syncex"

end
