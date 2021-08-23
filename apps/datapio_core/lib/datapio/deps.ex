defmodule Datapio.Dependencies do
  @moduledoc """
  Dependency Injection container.
  """

  def setup do
    :ets.new(__MODULE__, [:set, :public, :named_table])
  end

  def register(key, module) do
    :ets.insert(__MODULE__, {key, module})
  end

  def get(key) do
    :ets.lookup(__MODULE__, key) |> Keyword.fetch!(key)
  end
end
