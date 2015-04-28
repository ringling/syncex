defmodule AreaService do
	import CouchHelper

 	def all(country) do
	 	db = CouchHelper.postal_areas_db(country)
	 	{:ok, res} = Couchex.fetch_view(db, {"lists","all"},[])
	 	fetch_docs(res) |> Enum.map(fn(doc)-> parse_area(doc) end)
  end

	defp db_name(country) do
		country = country |> String.upcase
		areas_db = "#{country}_#{Settings.Couch.postal_areas_db}"
	end

  defp fetch_docs(docs) do
  	docs |> Enum.map(fn(doc)-> _value(doc) end)
  end

  defp _value({[{"id", id},{"key", _},{"value", value}]}), do: value

  defp parse_area({[__id, _rev,_type, {"id",id}, {"name",name}, {"postal_districts",postal_districts}, slug, conflicts]}) do
    %{id: id, name: name, postal_districts: parse_postal_districts(postal_districts,[])}
  end
  defp parse_area({[__id, _rev,_type, {"id",id}, {"name",name}, slug, {"postal_districts",postal_districts}]}) do
    %{id: id, name: name, postal_districts: parse_postal_districts(postal_districts,[])}
  end

  defp parse_postal_districts([], pds), do: pds
  defp parse_postal_districts([postal_district | postal_districts], pds) do
    {[_type, {"name", name}, {"id", id}, {"postal_codes", postal_codes}, slug, key]} = postal_district
    pd = %{id: id, name: name, postal_codes: parse_postal_codes(postal_codes, %{})}
    parse_postal_districts(postal_districts, [ pd | pds ])
  end

  defp parse_postal_codes([], pcs), do: pcs
  defp parse_postal_codes([postal_code | postal_codes], pcs) do
    {[{"postal_name", postal_name}, {"postal_code", postal_code}, _]} = postal_code
    pc = %{postal_name: postal_name, postal_code: postal_code}
    pcs = Map.put(pcs, postal_code, pc)
    parse_postal_codes(postal_codes, pcs)
  end

end
