defmodule Syncex.LocationSanitizer do

  @doc """
    Removes/replaces legacy and unclean location data
  """
  def sanitize(location) do
    location |> sanitize_postal_code |> map_category_to_type
  end

  defp sanitize_postal_code(location) do
    postal_code = location["postal_code"] |> String.strip |> adjust_postal_code
    location |> Map.put("postal_code", postal_code)
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

  defp map_category_to_type(location), do: map_category_to_type(has_type?(location), location)

  defp map_category_to_type(true, location), do: location
  defp map_category_to_type(false, location) do
    type = location |> Map.get("category", "user")
    location |> Map.put("type", type)
  end

  defp has_type?(location), do: Map.has_key?(location, "type")

end
