defmodule PipelineRunServer.Server.Registry do
  @moduledoc """
  Global Elixir process registry for the worker pool
  """

  use Horde.Registry

  def start_link(_args) do
    Horde.Registry.start_link(
      __MODULE__,
      [keys: :unique, members: :auto],
      name: __MODULE__
    )
  end

  def init(args) do
    Horde.Registry.init(args)
  end
end
