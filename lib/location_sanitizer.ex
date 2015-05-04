defmodule Syncex.LocationSanitizer do

  @doc """
    Removes/replaces legacy and unclean location data
    Aligns property data with location data for use in ElasticSearch
  """
  def sanitize(location) do
    location
    |> sanitize_postal_code
    |> map_category_to_type
    |> assure_both_address_lines_set
  end

  defp sanitize_postal_code(location) do
    postal_code = location["postal_code"] |> pc_to_str |> adjust_postal_code
    location |> Map.put("postal_code", postal_code)
  end

  defp pc_to_str(pc) when is_binary(pc),  do: pc |> String.strip
  defp pc_to_str(pc) when is_integer(pc), do: pc |> Integer.to_string

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
    type = location |> Map.get("category", "not_set")
    location |> Map.put("type", type)
  end

  # Because address_line 1 is named address_line1 in sales and address_line_1 in lease, we assure both are set.
  # Elastic searches are performed by address_line_1, but sales browser views need address_line1.
  # TODO: Remove when the two API's are alligned
  defp assure_both_address_lines_set(location) do
    address_line_1 = Map.get(location, "address_line1", Map.get(location, "address_line_1"))
    location |> Map.put("address_line_1", address_line_1) |> Map.put("address_line1", address_line_1)
  end

  defp has_type?(location), do: Map.has_key?(location, "type")

end
