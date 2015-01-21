defmodule LocationService do
  import CouchHelper
  require Logger

  def fetch_location({uuid, country}) do
    api_key = System.get_env("LB_INTERNAL_API_KEY")
    url = "#{api_url(country, uuid)}"
    case execute_get(url, api_key) do
      {:error, err} ->
        {:error, err}
      location ->
        Syncex.Sanitizer.sanitize(%{location: location})
          |> enrich(country, uuid, location["postal_code"])
    end
  end

  def max_sequence_number do
    max = location_types
      |> Enum.map( fn(type)->db_name(type) |> database |> fetch_stats |> max end)
      |> Enum.max
    max
  end

  defp location_types do
    System.get_env["LOCATION_TYPES"] |> String.split(",")
  end

  # Ignore danish Skåne locations
  defp enrich(_, "dk", _, postal_code) when byte_size(postal_code) > 4 do
    { :error, :danish_skaane_location }
  end

  defp enrich(location, country, uuid, postal_code) do
    pd = Syncex.Area.Server.postal_district(String.to_atom(country),postal_code)
    location = location
      |> Map.put(:uuid, uuid)
      |> Map.put(:country, country)
      |> Map.merge(pd)
    { :ok, location }
  end

  defp max({:error, :not_found}), do: 0
  defp max(stats) when map_size(stats)==0, do: 0
  defp max(stats), do: stats.max
  defp fetch_stats(database) do
    case Couchex.fetch_view(database, {"lists","max_seq_number"},[]) do
       {:ok, resp} ->
          resp |> parse_stats
      err ->
        {:error, :not_found}
    end
  end

  defp db_name(type) do
    type <> "_" <> System.get_env("COUCH_LOCATIONS_DB")
  end
  defp db_name do
    System.get_env("COUCH_LOCATIONS_DB")
  end
  defp parse_stats([]), do: %{}
  defp parse_stats([{ [_key,{"value", values}] }]) do
    {[{"sum", sum}, {"count", count}, {"min", min}, {"max", max}, {"sumsqr", sumsqr}]} = values
    %{ sum: sum, count: count, min: min, max: max, sumsqr: sumsqr}
  end

  defp api_url(country, location_uuid) do
    country = country |> String.upcase
    country_url = System.get_env("#{country}_URL")
    api_url = System.get_env("LB_INTERNAL_API_URL")
    "#{country_url}/#{api_url}/#{location_uuid}"
  end

end
