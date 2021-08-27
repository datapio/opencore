defmodule DatapioPipelineRunServer.Mnesia do
  @moduledoc """
  Initializes Mnesia
  """

  alias :mnesia, as: Mnesia

  def create_tables() do
    with :ok <- create_table(:requests, [:uid, :resource]),
         :ok <- create_table(:workers, [:worker_uid, :server_uid])
    do
      :ok
    else
      err -> err
    end
  end

  defp create_table(kind, attributes) do
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
end
