defmodule RabbitHelper do
  require Logger
  use AMQP
  use Timex

  def open_channel do
    {:ok, conn} = Connection.open(rabbit_mq_url)
    {:ok, chan} = Channel.open(conn)
    chan
  end

  def dispatch_synchronized_event({:ok, _couch_evt, location}, change, state, country) do
    json_msg = change.location |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    evt_type = "#{type(location["type"])}.synchronized"
    routing_key = "#{country}.#{evt_type}"
    AMQP.Basic.publish(state.channel, state.exchange, routing_key, json_msg, opts(evt_type, state.app_id))
  end

  def dispatch_synchronized_event({:error, error}, change, state, country) do
    Logger.error(inspect error)
    evt_type = "#{type_from_meta(change.meta.type)}.synchronize_failed"
    %{change: change, error: error} |> publish(state, country, evt_type)
  end

  def dispatch_synchronized_event({:error, error, location}, change, state, country) do
    Logger.error(inspect error)
    evt_type = "#{type(location["type"])}.synchronize_failed"
    %{change: change, error: error} |> publish(state, country, evt_type)
  end

  defp publish(msg, state, country, evt_type) do
    routing_key = "#{country}.#{evt_type}"
    json_msg = msg |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    AMQP.Basic.publish(state.channel, state.exchange, routing_key, json_msg, opts(evt_type, state.app_id))
  end

  def add_metadata({:error, err_message}, _), do: {:error, err_message}
  def add_metadata({:ok, location}, change)   do
    metadata = %{
      type: change.meta.type,
      message_id: change.meta.message_id,
      timestamp: change.meta.timestamp,
      updated_date: DateFormat.format!(Date.local, "{ISO}")
    }

    location |> Map.put(:metadata, metadata)
  end

  defp type_from_meta(type), do: String.split(type,".") |> hd

  defp type("lease"),       do: "location"
  defp type("user"),        do: "property"
  defp type("investment"),  do: "property"

  defp opts(evt_type, app_id), do: [persistent: true, type: evt_type, app_id: app_id, content_type: "application/json"]

  defp rabbit_mq_url, do: System.get_env("RABBITMQ_URL")

end
