defmodule Syncex.AreaServerTest do
  use ExUnit.Case, async: true
  alias Syncex.Area.Server

  @pc_naerum "2850"

  setup do
    {:ok, area_server} = Syncex.Area.Server.start_link(Syncex.Area.Server,%{areas: areas})
    {:ok, area_server: area_server}
  end

  test "find postal_district", %{area_server: area_server} do
    pd = %{area_ids: ["nordsj"], postal_district_id: @pc_naerum}
    assert pd = Server.postal_district(area_server, :dk, @pc_naerum)
  end

  defp areas do
    postal_code = %{postal_code: @pc_naerum}
    postal_codes = Map.put(%{}, @pc_naerum, postal_code)
    pd = %{id: @pc_naerum, name: "Nærum", postal_codes: postal_codes}
    area = %{id: "nordsj", name: "Nordsjælland", postal_districts: [pd]}
    HashDict.new |> HashDict.put(:dk, [area])
  end

end
