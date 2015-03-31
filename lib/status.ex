defmodule Syncex.Status do

  def in_sync?(service \\ %{sequence_server: Syncex.Sequence.Server, location_service: LocationService}) do
    current_seq(service.sequence_server) == max_seq(service.location_service)
  end

  defp current_seq(sequence_server), do: sequence_server.get_sequence

  defp max_seq(location_service), do: location_service.max_sequence_number

end
