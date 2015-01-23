defmodule Syncex.Area.Server do
  use GenServer
  require Logger

  #####
  # External API
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def start_link(name, %{areas: areas}) do
    GenServer.start_link(__MODULE__, areas, [name: name])
  end

  def init(:ok) do
    fetch_all_areas |> init
  end

  def init(areas) do
    Logger.info "Area server started - #{HashDict.size(areas)} area(s) loaded"
    {:ok, areas}
  end

  def postal_district(country, postal_code), do: postal_district(__MODULE__, country, postal_code)
  def postal_district(server, country, postal_code) do
    GenServer.call(server, {:postal_district, country, postal_code})
  end

  defp fetch_all_areas do
    add_areas([:dk, :se], HashDict.new)
  end

  defp add_areas([], all_areas), do: all_areas
  defp add_areas([country | countries], all_areas) do
    areas = AreaService.all(country)
    all_areas = all_areas |> HashDict.put(country, areas)
    add_areas(countries, all_areas)
  end

  #####
  # GenServer implementation
  def handle_call({:postal_district, country, postal_code}, _from, areas) do
    country_areas = areas |> HashDict.get(country)
    pd = find_postal_district(country_areas, postal_code, nil)

    found_in_areas = country_areas
      |> Enum.reject(fn(area)->!includes_postal_district?(area, pd) end)
      |> Enum.map(fn(area)-> area.id end)

    postal_district = %{}
     |> Map.put(:postal_district_id, pd.id)
     |> Map.put(:area_ids, found_in_areas)


    { :reply, postal_district, areas }
  end

  defp find_postal_district([], postal_code, nil), do: nil
  defp find_postal_district([area | areas], postal_code, nil) do
    pd = area.postal_districts |> includes_postal_code?(postal_code)
    find_postal_district(areas, postal_code, pd)
  end
  defp find_postal_district(_, _, pd), do: pd

  defp includes_postal_district?(area, postal_district) do
    area.postal_districts |> Enum.find(fn(pd)-> pd.id == postal_district.id end)
  end

  defp includes_postal_code?(postal_districts, postal_code) do
    postal_districts |> Enum.find(fn(pd)-> pd.postal_codes |> Map.has_key?(postal_code) end)
  end

  defp find_areas([], postal_code, found_in_areas), do: found_in_areas
  defp find_areas([area | areas], postal_code, found_in_areas) do

  end

end
