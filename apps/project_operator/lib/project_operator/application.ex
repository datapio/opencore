defmodule ProjectOperator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Highlander, ProjectOperator.Controller}
    ]

    opts = [strategy: :one_for_one, name: ProjectOperator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
