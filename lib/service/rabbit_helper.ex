defmodule RabbitHelper do
  use AMQP

  def open_channel do
    {:ok, conn} = Connection.open(rabbit_mq_url)
    {:ok, chan} = Channel.open(conn)
    chan
  end

  defp rabbit_mq_url, do: System.get_env("RABBITMQ_URL")

end
