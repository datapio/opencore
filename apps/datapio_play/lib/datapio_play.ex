defmodule Datapio.Play do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      require Datapio.Play.Manifest
      import Datapio.Play.Manifest
      use Datapio.Play.DSL

      :ets.new(:datapio_play_config, [:set, :public, :named_table])

      unquote(opts) |> Enum.each(fn entry ->
        :ets.insert(:datapio_play_config, entry)
      end)
    end
  end
end
