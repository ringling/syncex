defmodule EventService do
  import CouchHelper

  def latest_event(location) do
    # couch_url(location[:country], location)

    # curl http://sofa.lokalebasen.dk:5984/events/_all_docs\?include_docs\=true | jq '.["rows"] | length'

    # api_key = System.get_env("LB_INTERNAL_API_KEY")

    # url = "#{api_url(country, uuid)}"

    # case execute_get(url, api_key) do
    #   {:error, err} ->
    #     {:error, err}
    #   location ->
    #     location = location |> Map.put(:uuid, uuid)
    #     { :ok, location }
    # end
  end

  defp db_name do
    System.get_env("COUCH_EVENTS_DB")
  end

end
