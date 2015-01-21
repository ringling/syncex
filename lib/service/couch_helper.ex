defmodule CouchHelper do
  require Logger

  def event_db do
    { :ok, db } = Couchex.open_db(server, System.get_env("COUCH_EVENTS_DB"))
    db
  end

  def postal_areas_db(country) do
    database_name = "#{country}_#{System.get_env("COUCH_POSTAL_AREAS_DB")}"
    { :ok, db } = Couchex.open_db(server, database_name)
    db
  end

  def server do
    (System.get_env["COUCH_SERVER_URL"] || "http://localhost:5984")
      |> Couchex.server_connection([])
  end

  def ping do
    server_connection |> Couchex.server_info |> _response
  end

  def value({[_,_,{_,value}]}), do: value
  def fetch_response({:ok, response}), do: response
  def db_name(country, dbname), do: "#{country}_#{dbname}"
  def db_name(country, category, dbname), do: "#{country}_#{category}_#{dbname}"

  def map_values(list, map_fun) do
    list |> Enum.map fn(map) -> value(map) |> map_fun.() end
  end

  def database(database_name) do
    server_connection |> Couchex.open_db(database_name) |> fetch_response
  end

  def server_connection do
    couchdb_url = System.get_env["COUCH_SERVER_URL"]
    user = System.get_env["COUCH_USER"]
    pass = System.get_env["COUCH_PASS"]
    Couchex.server_connection(couchdb_url, [{:basic_auth, {user, pass}}])
  end

  def couch_url(country, location) do
    server_url = System.get_env("COUCH_SERVER_URL")
    country = country |> String.upcase
    type = location["type"] |> String.downcase
    locations_db = type <> "_" <> System.get_env("COUCH_LOCATIONS_DB")
    url = "#{server_url}/#{locations_db}/#{location.uuid}"
    add_revision(url)
  end

  def execute_get(url, api_key) do
    try do
      case HTTPotion.get(url, ["Api-Key": api_key]) do
        %HTTPotion.Response{status_code: 200, body: body} ->
          body |> Poison.decode!
        %HTTPotion.Response{status_code: 404} ->
          {:error, :not_found}
        %HTTPotion.Response{status_code: 500} ->
          {:error, :server_error}
        %HTTPotion.Response{status_code: 400} ->
          {:error, :invalid_request}
      end
    rescue
      e in HTTPotion.HTTPError -> {:error, e.message }
      e in RuntimeError -> {:error, e}
      e in Error -> {:error, "Unknown error #{inspect e}"}
    end
  end

  def execute_post({location, event_doc}) do
    country = event_doc.country
    { action, url } = couch_url(country, location) |> action
    json = Poison.Encoder.encode(location, [])
    try do
      case HTTPotion.put(url, json,["Content-Type": "application/json"]) do
        %HTTPotion.Response{status_code: 201, body: body} ->
          resp = body |> Poison.decode!
          id = resp["id"]
          Logger.info "Location(#{country}) #{action} #{id}"
          { :ok, :created }
        %HTTPotion.Response{status_code: 200, body: body} ->
          resp = body |> Poison.decode!
          id = resp["id"]
          Logger.info "Location(#{country}) #{action} #{id}"
          IO.inspect body |> Poison.decode!
          { :ok, :updated }
        %HTTPotion.Response{status_code: 409} ->
          Logger.error "CONFLICT Location(#{country}) #{location.uuid}"
          {:error, :conflict}
        %HTTPotion.Response{status_code: 404} ->
          Logger.error "NOT FOUND Location(#{country}) #{location.uuid}"
          {:error, :not_found}
        %HTTPotion.Response{status_code: 400} ->
          Logger.error "INVALID REQUEST Location(#{country}) #{location.uuid}"
          {:error, :invalid_request}
        %HTTPotion.Response{status_code: 500} ->
          Logger.error "SERVER ERROR Location(#{country}) #{location.uuid}"
          {:error, :server_error}
        error ->
          {:error, "Unknown: #{inspect error}"}
      end
    rescue
      e in HTTPotion.HTTPError -> {:error, e.message }
      e in RuntimeError -> {:error, e}
      e in Error -> {:error, "Unknown error #{inspect e}"}
    end
    { :ok, :update }

  end

  defp action({ :error,       err }), do: { :error,  err }
  defp action({ :no_revision, url }), do: { :create, url }
  defp action({ :revision,    url }), do: { :update, url }

  defp _response({:error, msg }),  do: {:error, "couchdb"}
  defp _response({:ok,    _   }),    do: {:ok, "couchdb"}

  defp add_revision(url) do
    try do
      case HTTPotion.head(url) do
        %HTTPotion.Response{status_code: 200, headers: headers} ->
          rev = headers[:ETag] |> String.strip(?")
          { :revision, "#{url}?rev=#{rev}" }
        %HTTPotion.Response{status_code: 404, headers: headers} ->
          { :no_revision, url }
        error ->
          {:error, error}
      end
    rescue
      e in HTTPotion.HTTPError -> {:error, e.message }
      e in RuntimeError -> {:error, e}
      e in Error -> {:error, "Unknown error #{inspect e}"}
    end
  end


end
