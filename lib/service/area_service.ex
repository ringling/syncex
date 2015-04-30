defmodule AreaService do
  import CouchHelper

  def all(country) do
    db = CouchHelper.postal_areas_db(country)
    {:ok, res} = Couchex.fetch_view(db, {"lists","all"},[])
    fetch_docs(res) |> Enum.map(fn(doc)-> doc |> convert_to_map |> parse_area end)
  end

  defp db_name(country) do
    country = country |> String.upcase
    areas_db = "#{country}_#{Settings.Couch.postal_areas_db}"
  end

  defp fetch_docs(docs) do
    docs |> Enum.map(fn(doc)-> doc |> convert_to_map |> _value end)
  end

  defp convert_to_map({touple_list}) do
    touple_list |> Enum.into %{}
  end

  defp _value(%{"value" => value}), do: value

  defp parse_area(%{"id" => id, "name" => name, "postal_districts" => postal_districts}) do
    %{id: id, name: name, postal_districts: parse_postal_districts(postal_districts,[])}
  end

  defp parse_postal_districts([], pds), do: pds
  defp parse_postal_districts([postal_district | postal_districts], pds) do
    %{"name" => name, "id" => id, "postal_codes" => postal_codes} = convert_to_map(postal_district)
    pd = %{id: id, name: name, postal_codes: parse_postal_codes(postal_codes, %{})}
    parse_postal_districts(postal_districts, [ pd | pds ])
  end

  defp parse_postal_codes([], pcs), do: pcs
  defp parse_postal_codes([postal_code | postal_codes], pcs) do
    %{"postal_name" => postal_name, "postal_code" => postal_code} = convert_to_map(postal_code)
    pc = %{postal_name: postal_name, postal_code: postal_code}
    pcs = Map.put(pcs, postal_code, pc)
    parse_postal_codes(postal_codes, pcs)
  end

end
