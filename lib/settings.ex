defmodule Settings do

  defmodule Couch do
    def server_url, do: (System.get_env["COUCH_SERVER_URL"] || "http://localhost:5984")
    def postal_areas_db, do: System.get_env("COUCH_POSTAL_AREAS_DB")
    def locations_db, do: System.get_env("COUCH_LOCATIONS_DB")
    def user, do: System.get_env["COUCH_USER"]
    def pass, do: System.get_env["COUCH_PASS"]
  end

  defmodule Rabbit do
    def server_url, do: System.get_env("RABBITMQ_URL")
    def routing_keys do
      [
        (System.get_env("RABBITMQ_LOCATIONS_ROUTING_KEY") || "*.location.*"),
        (System.get_env("RABBITMQ_PROPERTY_ROUTING_KEY") || "*.property.*")
      ]
    end
    def exchange, do: System.get_env("RABBITMQ_EXCHANGE") || "lb"
    def queue, do: System.get_env("RABBITMQ_QUEUE") || "syncex"
  end

  defmodule InternalApi do
    def api_key, do: System.get_env("LB_INTERNAL_API_KEY")
  end

end


