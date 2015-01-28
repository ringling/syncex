defmodule Syncex.LocationSanitizerTest do
  use ExUnit.Case

  alias Syncex.LocationSanitizer

  test "should strip postal_codes" do
    location = %{"postal_code" => "4300 "}
    assert "4300" ==  LocationSanitizer.sanitize(location)["postal_code"]
  end

  test "should replace invalid postal_codes" do
    location = %{"postal_code" => "1404"}
    assert "1460" ==  LocationSanitizer.sanitize(location)["postal_code"]
  end

end
