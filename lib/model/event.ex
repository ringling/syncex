defmodule Syncex.Event do

  def doc({[{"seq", seq}, {"id",_}, {"changes", _ }, {"doc", doc } | _]}), do: { seq, doc }
  def doc({[{"seq", seq}, {"id",_}, {"changes", _ }, _,  {"doc", doc } | _]}), do: { seq, doc }

  def from_doc([
      {"_id", id},
      {"_rev", rev},
      {"location_uuid", location_uuid},
      {"name", event_name},
      {"created_at", created_at},
      {"app", app},
      {"country", country}
      | _tail
    ]) do

    %{id: id, location_uuid: location_uuid, event_name: event_name, created_at: created_at, app: app, country: country }
  end
  def from_doc(_), do: { :error, :no_match }

end
