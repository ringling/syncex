defmodule CouchHelper do
  require Logger

  def postal_areas_db(country) do
    database_name = "#{country}_#{Settings.Couch.postal_areas_db}"
    { :ok, db } = Couchex.open_db(server, database_name)
    db
  end

  def server do
    server_url |> Couchex.server_connection([])
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
    user = Settings.Couch.user
    pass = Settings.Couch.pass
    server_url |> Couchex.server_connection([{:basic_auth, {user, pass}}])
  end

  def couch_url(location) do
    url = "#{server_url}/#{locations_db(location)}/#{location.uuid}"
    add_revision(url)
  end

  defp locations_db(location) do
    category = location["type"] |> String.downcase
    category <> "_" <> Settings.Couch.locations_db
  end

  def update_location({:error, err_message}), do: {:error, err_message}
  def update_location(location), do:  execute_post(location)

  def execute_get(url, api_key) do
    try do
      case HTTPotion.get(url, ["Api-Key": api_key]) do
        %HTTPotion.Response{status_code: 200, body: body} ->
          body |> Poison.decode!
        %HTTPotion.Response{status_code: 404} ->
          Logger.error "#{__MODULE__}.execute_get: Not found(404), url: #{url}"
          {:error, :not_found}
        %HTTPotion.Response{status_code: 500} ->
          Logger.error "#{__MODULE__}.execute_get: Server error(500), url: #{url}"
          {:error, :server_error}
        %HTTPotion.Response{status_code: 400} ->
          Logger.error "#{__MODULE__}.execute_get: Invalid request(400), url: #{url}"
          {:error, :invalid_request}
      end
    rescue
      e in HTTPotion.HTTPError -> {:error, e.message }
      e in RuntimeError -> {:error, e}
      e in Error -> {:error, "Unknown error #{inspect e}"}
    end
  end

  def execute_post(location) do
    {action, url} = couch_url(location) |> action
    json = Poison.Encoder.encode(location, [])
    try do
      case HTTPotion.put(url, json,["Content-Type": "application/json"]) do
        %HTTPotion.Response{status_code: 201, body: body} ->
          resp = body |> Poison.decode!
          id = resp["id"]
          Logger.info "#{__MODULE__}.execute_post: #{action} #{id}"
          { :ok, action, location}
        %HTTPotion.Response{status_code: 200, body: body} ->
          resp = body |> Poison.decode!
          id = resp["id"]
          Logger.info "#{__MODULE__}.execute_post: #{action} #{id}"
          IO.inspect body |> Poison.decode!
          {:ok, action, location}
        %HTTPotion.Response{status_code: 409} ->
          Logger.error "#{__MODULE__}.execute_post: Conflict(409), url: #{url}"
          {:error, :conflict, location}
        %HTTPotion.Response{status_code: 404} ->
          Logger.error "#{__MODULE__}.execute_post: Not found(404), url: #{url}"
          {:error, :not_found, location}
        %HTTPotion.Response{status_code: 400} ->
          Logger.error "#{__MODULE__}.execute_post: Invalid request(400), url: #{url}"
          {:error, :invalid_request, location}
        %HTTPotion.Response{status_code: 500} ->
          Logger.error "#{__MODULE__}.execute_post: Server error(500), url: #{url}"
          {:error, :server_error, location}
        error ->
          Logger.error "#{__MODULE__}.execute_post: Unknown error '#{inspect error}', url: #{url}"
          {:error, "#{__MODULE__}.execute_post: Unknown -> #{inspect error}", location}
      end
    rescue
      e in HTTPotion.HTTPError -> {:error, e.message, location}
      e in RuntimeError -> {:error, e, location}
      e in Error -> {:error, "Unknown error #{inspect e}", location}
    end
  end

  defp server_url, do: Settings.Couch.server_url

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
          Logger.error("#{__MODULE__}.add_revision error '#{inspect error}', url: #{url}")
          {:error, error}
      end
    rescue
      e in HTTPotion.HTTPError -> {:error, e.message }
      e in RuntimeError -> {:error, e}
      e in Error -> {:error, "Unknown error #{inspect e}"}
    end
  end


end
