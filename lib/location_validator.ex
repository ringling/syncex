defmodule LocationValidator do

  def validate(location, country) do
    location
      |> validate_postal_code(country)
      |> validate_coordinates
  end

  defp validate_coordinates({:error, error}), do: {:error, error}
  defp validate_coordinates(location)         do
    coordinates = (location |> Map.get("location", %{})) || %{}
    invalid =
      is_nil(Map.get(coordinates, "lon", nil)) || is_nil(Map.get(coordinates, "lat", nil))
    validate_coordinates(location, invalid)
  end
  defp validate_coordinates(_, true),         do: {:error, :invalid_coordinates}
  defp validate_coordinates(location, false), do: location


  defp validate_postal_code({:error, error}, _),  do: {:error, error}
  defp validate_postal_code(location, country)    do
    validate_postal_code(location, location["postal_code"], country)
  end

  def validate_postal_code(_, postal_code, "dk") when byte_size(postal_code) > 4 do
    { :error, :danish_skaane_location }
  end
  def validate_postal_code(location, _, _), do: location

end
