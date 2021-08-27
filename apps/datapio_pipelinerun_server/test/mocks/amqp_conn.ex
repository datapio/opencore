defmodule DatapioMock.AMQP.Conn do
  @moduledoc false

  def open(url) do
    {:ok, {:amqp_connection, [url: url]}}
  end
end
