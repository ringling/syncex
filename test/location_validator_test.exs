defmodule LocationValidatorTest do
  use ExUnit.Case

   test "valid location should pass" do
    assert dk_skaane_location == LocationValidator.validate(dk_skaane_location, "se")
  end

  test "danish skaane location should fail" do
    assert { :error, :danish_skaane_location } == LocationValidator.validate(dk_skaane_location, "dk")
  end

  test "coordinates missing should fail" do
    assert { :error, :invalid_coordinates } == LocationValidator.validate(coordinates_missing, "se")
  end

  test "lat/lon missing should fail" do
    assert {:error, :invalid_coordinates} == LocationValidator.validate(lat_lon_missing, "se")
  end

  test "lat missing should fail" do
    assert {:error, :invalid_coordinates} == LocationValidator.validate(lat_missing, "se")
  end

  test "lon missing should fail" do
    assert {:error, :invalid_coordinates} == LocationValidator.validate(lon_missing, "se")
  end

  def coordinates_missing  do
    %{
      "location" => nil,
      "postal_code" => "21228", "postal_name" => "Malmö",
      "provider_uuid" => "78e291e2-af43-4607-bdb9-6a2dbeb57b19"
    }
  end

  def lat_missing  do
    %{
      "location" => %{"lat" => nil, "lon" => 13.0426651},
      "postal_code" => "21228", "postal_name" => "Malmö",
      "provider_uuid" => "78e291e2-af43-4607-bdb9-6a2dbeb57b19"
    }
  end

  def lon_missing  do
    %{
      "location" => %{"lat" => 55.6017544, "lon" => nil},
      "postal_code" => "21228", "postal_name" => "Malmö",
      "provider_uuid" => "78e291e2-af43-4607-bdb9-6a2dbeb57b19"
    }
  end

  def lat_lon_missing  do
    %{
      "location" => %{"lat" => nil, "lon" => nil},
      "postal_code" => "21228", "postal_name" => "Malmö",
      "provider_uuid" => "78e291e2-af43-4607-bdb9-6a2dbeb57b19"
    }
  end

  def dk_skaane_location  do
    %{
      "location" => %{"lat" => 55.6017544, "lon" => 13.0426651},
      "postal_code" => "21228", "postal_name" => "Malmö",
      "provider_uuid" => "78e291e2-af43-4607-bdb9-6a2dbeb57b19"
    }
  end

end
