defmodule Datapio.Play.StepLogger do
  @moduledoc """
  Print logs from steps.
  """

  defstruct [:prefix]

  def new() do
    book = case :ets.lookup(:datapio_play_config, :current_book) do
      [] -> "no name"
      [{:current_book, name}] -> name
    end
    task = case :ets.lookup(:datapio_play_config, :current_task) do
      [] -> "no name"
      [{:current_task, name}] -> name
    end
    step = case :ets.lookup(:datapio_play_config, :current_step) do
      [] -> "no name"
      [{:current_step, name}] -> name
    end

    prefix = IO.ANSI.format([:blue, "Book(#{book}) > Task(#{task}) > Step(#{step}) >>> "])
    %__MODULE__{prefix: prefix}
  end

  def print(%__MODULE__{} = logger, msg) do
    msg
      |> String.split(~r/\R/)
      |> Stream.filter(fn s -> String.length(s) > 0 end)
      |> Enum.each(fn s -> IO.puts("#{logger.prefix}#{s}") end)
  end
end
