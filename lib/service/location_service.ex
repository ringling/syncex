defmodule LocationService do
  import CouchHelper

  def fetch_location({country, uuid}) do
    api_key = System.get_env("LB_INTERNAL_API_KEY")
    url = "#{api_url(country, uuid)}"
    case execute_get(url, api_key) do
      {:error, err} ->
        {:error, err}
      location ->
        location = location
          |> Map.put(:uuid, uuid)
          |> Map.put(:country, country)
        { :ok, location }
    end
  end

  def max_sequence_number do
    ["dk","se"]
      |> Enum.map( fn(cntry)->db_name(cntry) |> database |> fetch_stats |> max end)
      |> Enum.max
  end

  defp max(stats), do: stats.max
  defp max(_), do: 0
  defp fetch_stats(database) do
    case Couchex.fetch_view(database, {"lists","max_seq_number"},[]) do
       {:ok, resp} ->
          resp |> parse_stats
      err ->
        {:error, :not_found}
    end
  end

  defp db_name(country) do
    cntry = country |> String.upcase
    System.get_env("#{cntry}_COUCH_LOCATION_DB")
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
