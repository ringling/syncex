defmodule Syncex.EventTest do
  use ExUnit.Case, async: true
  alias Syncex.Area.Server


  test "event is valid" do
    assert Syncex.Event.is_valid_event?("property.created")
    assert Syncex.Event.is_valid_event?("location.created")
  end

  test "event is invalid" do
    refute Syncex.Event.is_valid_event?("property.foo")
    refute Syncex.Event.is_valid_event?("location.bar")
  end

end
