defmodule Syncex.ErrorStackTest do
  use ExUnit.Case

  setup do
  	{:ok, stack} = Syncex.ErrorStack.start_link
    {:ok, stack: stack}
  end

  test "push error", %{stack: stack} do
  	error = %{ data: {"event_doc", "seq_number"}, error: {:error, "msg" }}
  	assert :ok = Syncex.ErrorStack.push(stack, error)
  	refute 2 = Syncex.ErrorStack.total(stack)
  	assert 1 = Syncex.ErrorStack.total(stack)
  end

  test "stack size", %{stack: stack} do
  	error = %{ data: {"event_doc", "seq_number"}, error: {:error, "msg" }}
  	assert 0 = Syncex.ErrorStack.total(stack)
  	Syncex.ErrorStack.push(stack, error)
  	Syncex.ErrorStack.push(stack, error)
  	assert 2 = Syncex.ErrorStack.total(stack)
  	assert error = Syncex.ErrorStack.pop(stack)
  	assert 1 = Syncex.ErrorStack.total(stack)
  end

  test "pop error", %{stack: stack} do
  	error = %{ data: {"event_doc", "seq_number"}, error: {:error, "msg" }}
  	Syncex.ErrorStack.push(stack, error)
  	assert error = Syncex.ErrorStack.pop(stack)
  end

   test "pop when no errors", %{stack: stack} do
  	error = %{ data: {"event_doc", "seq_number"}, error: {:error, "msg" }}
  	assert nil = Syncex.ErrorStack.pop(stack)
  end

end
