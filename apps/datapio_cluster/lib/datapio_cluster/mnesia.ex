defmodule Datapio.Cluster.Mnesia do
  @moduledoc """
  Mnesia (ram copies only) initialization functions.

  To automatically create tables on startup, add this to your
  `config/config.exs`:

  ```elixir
  config :datapio_cluster,
    cache_tables: [
      my_table: [:attr1, :attr2]
    ]
  ```
  """

  alias :mnesia, as: Mnesia

  @doc "Create tables defined in application configuration."
  @spec init_from_config() :: :ok | {:error, term()}
  def init_from_config() do
    Application.get_env(:datapio_cluster, :cache_tables, [])
      |> create_tables()
  end

  @doc "Create an Mnesia table."
  @spec create_table(atom(), [atom(), ...]) :: :ok | {:error, term()}
  def create_table(kind, attributes) do
    options = [
      attributes: attributes,
      type: :set
    ]

    case Mnesia.create_table(kind, options) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, _kind}} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp create_tables(tables) do
    create_tables(tables, :ok)
  end

  defp create_tables(_, {:error, reason}), do: {:error, reason}
  defp create_tables([], :ok), do: :ok
  defp create_tables([{kind, attributes} | tables], :ok) do
    result = create_table(kind, attributes)
    create_tables(tables, result)
  end
end
