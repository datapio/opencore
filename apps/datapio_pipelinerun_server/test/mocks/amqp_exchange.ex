defmodule DatapioMock.AMQP.Exchange do
  @moduledoc false

  def declare({:amqp_channel, _chan_opts} = _chan, _name, _type, _opts \\ []) do
    :ok
  end
end
