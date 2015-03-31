defmodule Syncex.StatusTest do
  use ExUnit.Case, async: true

  defmodule SequenceServerStub do
    def get_sequence, do: 1
  end

  defmodule LocationServiceStub do
    def max_sequence_number, do: 1
  end

  test "is in sync" do
    services = %{
      sequence_server: SequenceServerStub,
      location_service: LocationServiceStub
    }
    
    assert Syncex.Status.in_sync?(services)
  end

end
