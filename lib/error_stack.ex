defmodule Syncex.ErrorStack do

  @doc """
  Starts a new stack.
  """
  def start_link do
    Agent.start_link(fn -> [] end)
  end

  def start_link(name) do
    Agent.start_link(fn -> [] end, name: name)
  end

  def start_link(name, error_list) do
    Agent.start_link(fn -> error_list end, name: name)
  end

  @doc """
  Pop error
  """
  def pop,        do: pop(__MODULE__)
  def pop(stack) do
    Agent.get_and_update(stack, fn
      []    -> {nil, []}
      [h|t] -> {h, t}
    end)
  end

  @doc """
  Gets number of errors
  """
  def total,        do: total(__MODULE__)
  def total(stack) do
    Agent.get(stack, &(&1)) |> length
  end

  @doc """
  Push error to `stack`.
  """
  def push(error),          do: push(__MODULE__, error)
  def push(stack, error)   do
    Agent.update(stack, &[error|&1])
  end

end
