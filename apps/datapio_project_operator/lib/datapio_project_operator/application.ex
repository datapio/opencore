defmodule DatapioProjectOperator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Highlander, DatapioProjectOperator.Controller}
    ]

    opts = [strategy: :one_for_one, name: DatapioProjectOperator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
