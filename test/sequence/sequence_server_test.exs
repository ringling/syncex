defmodule Syncex.SequenceServerTest do
  use ExUnit.Case, async: true
  alias Syncex.Sequence.Server

  setup do
    {:ok, sequence_server} = Syncex.Sequence.Server.start_link
    {:ok, sequence_server: sequence_server}
  end

  test "get sequence number", %{sequence_server: sequence_server} do
    assert {:ok, 223} = Server.force_set_sequence(sequence_server, 223)
    assert 223 = Server.get_sequence(sequence_server)
  end

  test "set sequence number", %{sequence_server: sequence_server} do
    assert {:ok, 0} = Server.force_set_sequence(sequence_server, 0)
    assert {:ok, 1} = Server.set_sequence(sequence_server, 1)
    assert {:ok, 2} = Server.set_sequence(sequence_server, 2)
    assert {:ok, 3} = Server.set_sequence(sequence_server, 3)
   	assert {:ok, 4} = Server.set_sequence(sequence_server, 4)
    assert {:error, _, 7} = Server.set_sequence(sequence_server, 7)
   	assert {:ok, 5} = Server.set_sequence(sequence_server, 5)
  end

  test "force set sequence number", %{sequence_server: sequence_server} do
    assert {:ok, 223} = Server.force_set_sequence(sequence_server, 223)
    assert {:ok, 666} = Server.force_set_sequence(sequence_server, 666)
    refute {:ok, 666} = Server.force_set_sequence(sequence_server, 123)
    assert {:ok, 1} = Server.force_set_sequence(sequence_server, 1)
  end
end
