defmodule DatapioMqTest do
  use ExUnit.Case
  doctest DatapioMq

  test "greets the world" do
    assert DatapioMq.hello() == :world
  end
end
