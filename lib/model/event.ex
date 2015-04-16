defmodule Syncex.Event do

  def is_valid_event?(event_type), do: Enum.member?(valid_events, event_type)

  defp valid_events do
    [
      "location.created",
      "location.updated",
      "location.activated",
      "location.deactivated",
      "location.rented_out",
      "location.destroyed"
    ]
  end

end
