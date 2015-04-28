defmodule RabbitHelperTest do
  use ExUnit.Case, async: false
  import Mock

  test "add metadata" do
    meta = %{type: "TYPE", message_id: "MSG_ID", timestamp: "TS"}
    change = %{ meta: meta}
    location = %{}
    metadata = RabbitHelper.add_metadata({:ok, location}, change).metadata

    assert "TS" == metadata.timestamp
    assert "MSG_ID" == metadata.message_id
    assert "TYPE" == metadata.type
    assert  metadata |> Map.has_key?(:updated_date)
  end

  test "add metadata error" do
    err = {:error, "AN_ERROR"}
    assert err == RabbitHelper.add_metadata(err, nil)
  end

  test "dispatching location synchronized event" do
    state = %{channel: "CHANNEL", exchange: "EXCHANGE", app_id: "APP_ID"}
    location = %{"type" => "lease"}
    change = %{location: location}
    json_msg = "{\"type\":\"lease\"}"

    options = [persistent: true, type: "location.synchronized", app_id: "APP_ID", content_type: "application/json"]

    with_mock AMQP.Basic, [publish: fn(channel,exchange,routing_key,json, opts) -> {channel, exchange, routing_key, json, opts} end] do
      {channel, exchange, routing_key, json, opts} = RabbitHelper.dispatch_synchronized_event({:ok, "couch_evt", location}, change, state, "dk")
      assert {channel, exchange, routing_key, json, opts} == {"CHANNEL","EXCHANGE","dk.location.synchronized",json_msg, options}
    end

  end

  test "dispatching property synchronized event" do
    state = %{channel: "CHANNEL", exchange: "EXCHANGE", app_id: "APP_ID"}
    location = %{"type" => "user"}
    change = %{location: location}
    json_msg = "{\"type\":\"user\"}"
    country = "dk"

    options = [persistent: true, type: "property.synchronized", app_id: state.app_id, content_type: "application/json"]

    with_mock AMQP.Basic, [publish: fn(channel, exchange, routing_key, json, opts) -> {channel, exchange, routing_key, json, opts} end] do
      {channel, exchange, routing_key, json, opts} = RabbitHelper.dispatch_synchronized_event({:ok, "couch_evt", location}, change, state, country)
      assert {channel, exchange, routing_key, json, opts} == {state.channel, state.exchange, "#{country}.property.synchronized", json_msg, options}
    end
  end

  test "dispatching synchronize_failed event" do
    state = %{channel: "CHANNEL", exchange: "EXCHANGE", app_id: "APP_ID"}
    location = %{"type" => "user"}
    change = %{location: location}
    json_msg = "{\"error\":\"error\",\"change\":{\"location\":{\"type\":\"user\"}}}"
    country = "dk"

    options = [persistent: true, type: "property.synchronize_failed", app_id: state.app_id, content_type: "application/json"]

    with_mock AMQP.Basic, [publish: fn(channel, exchange, routing_key, json, opts) -> {channel, exchange, routing_key, json, opts} end] do
      {channel, exchange, routing_key, json, opts} = RabbitHelper.dispatch_synchronized_event({:error, "error", location}, change, state, country)
      assert {channel, exchange, routing_key, json, opts} == {state.channel, state.exchange, "#{country}.property.synchronize_failed", json_msg, options}
    end

  end

end
