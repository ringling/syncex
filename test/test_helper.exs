ExUnit.start()

defmodule Logger do
  def log(_,_,_), do: :ok
  def flush, do: :ok
end
