defmodule LocationService do
  import CouchHelper
  require Logger

  def fetch_location({uuid, country, api_url}) do
    case execute_get(api_url, api_key) do
      {:error, err} ->
        {:error, err}
      location ->
        location
          |> Syncex.LocationSanitizer.sanitize
          |> LocationValidator.validate(country)
          |> enrich(country, uuid)
    end
  end

  defp enrich({ :error, error }, _, _),  do: { :error, error }
  defp enrich(location, country, uuid)   do
    pd = Syncex.Area.Server.postal_district(String.to_atom(country), location["postal_code"])
    location = location
      |> Map.put(:uuid, uuid)
      |> Map.put(:country, country)
      |> Map.merge(pd)
    { :ok, location }
  end

  defp api_key, do: Settings.InternalApi.api_key

end
