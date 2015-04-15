defmodule Syncex.StatusTest do
  use ExUnit.Case, async: true


  setup do
    {:ok, status_server} = Syncex.Status.start_link
    {:ok, status_server: status_server}
  end

  defmodule SequenceServerStub do
    def get_sequence, do: 99
  end

  defmodule LocationServiceNotInSyncStub do
    def max_sequence_number, do: 1
  end

  defmodule LocationServiceInSyncStub do
    def max_sequence_number, do: 99
  end

  defmodule UpdateWorkerStub do
    def latest_synced_event, do: :event
  end

  test "is in sync" do
    services = %{
      sequence_server: SequenceServerStub,
      location_service: LocationServiceInSyncStub
    }
    assert Syncex.Status.in_sync?(services)
  end

  test "is not in sync" do
    services = %{
      sequence_server: SequenceServerStub,
      location_service: LocationServiceNotInSyncStub
    }
    refute Syncex.Status.in_sync?(services)
  end

  test "latest synced event" do
    assert Syncex.Status.latest_synced_event(UpdateWorkerStub) == :event
  end

end
