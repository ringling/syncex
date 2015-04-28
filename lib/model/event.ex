defmodule Syncex.Event do

  def is_valid_event?(event_type), do: Enum.member?(valid_events, event_type)

  defp valid_events do
    property_events ++ location_events
  end

  defp property_events do
    [
      "property.activated",
      "property.updated",
      "property.deactivated",
      "property.created"
    ]
  end

  defp location_events do
    [
      "location.created",
      "location.updated",
      "location.activated",
      "location.deactivated",
      "location.rented_out"
    ]
  end

end
