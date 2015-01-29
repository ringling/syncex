defmodule Syncex.LocationSanitizer do

  @doc """
    Removes/replaces legacy and unclean location data
  """
  def sanitize(location) do
    postal_code = location["postal_code"]
      |> String.strip
      |> adjust_postal_code
    location |> Map.put("postal_code",postal_code)
  end

  defp adjust_postal_code("1404"), do: "1460"
  defp adjust_postal_code("1000"), do: "1455"
  defp adjust_postal_code("1258"), do: "1253"
  defp adjust_postal_code("1010"), do: "1160"
  defp adjust_postal_code("1016"), do: "1123"
  defp adjust_postal_code("1092"), do: "1060"
  defp adjust_postal_code("1002"), do: "1164"
  defp adjust_postal_code("1162"), do: "1159"
  defp adjust_postal_code("1007"), do: "1070"
  defp adjust_postal_code(postal_code), do: postal_code

end
