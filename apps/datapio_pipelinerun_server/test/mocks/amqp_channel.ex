defmodule DatapioMock.AMQP.Channel do
  @moduledoc false

  def open({:amqp_connection, _opts} = conn) do
    {:ok, {:amqp_channel, [conn: conn]}}
  end
end
