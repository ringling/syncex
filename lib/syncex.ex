defmodule Syncex do
  use Application

  @update_worker Syncex.UpdateWorker
  @area Syncex.Area.Server
  @location_service LocationService
  @location_listener Syncex.LocationListener
  @ten_minutes 60*1000*10

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Dotenv.load!

    rabbit_opts = %{exchange: exchange, queue: queue, routing_keys: routing_keys, app_id: "syncex"}
    ll_opts = rabbit_opts |> Map.put(:worker, @update_worker)

    children = [
      worker(Syncex.DmsNotifier, [@ten_minutes]),
      worker(Syncex.Area.Server, [@area]),
      worker(GenServer, [@update_worker, rabbit_opts, [name: @update_worker]]),
      worker(Syncex.LocationListener, [ll_opts, [name: @location_listener]]),
      worker(Syncex.Status, [])
    ]

    opts = [strategy: :one_for_one, name: Syncex.Supervisor, max_restarts: 1000, max_seconds: 10]
    Supervisor.start_link(children, opts)
  end

  defp routing_keys do
    [
      (System.get_env("RABBITMQ_LOCATIONS_ROUTING_KEY") || "*.location.*"),
      (System.get_env("RABBITMQ_PROPERTY_ROUTING_KEY") || "*.property.*")
    ]
  end

  defp exchange, do: System.get_env("RABBITMQ_EXCHANGE") || "lb"

  defp queue, do: System.get_env("RABBITMQ_QUEUE") || "syncex"

end
