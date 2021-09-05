defmodule Datapio.Play.Utilities do
  @moduledoc false

  alias Datapio.Play.StepFailedError

  def discover_books() do
    books_dir = case :ets.lookup(:datapio_play_config, :books_dir) do
      [{:books_dir, dirname}] -> dirname
      [] -> "playbooks"
    end

    File.cwd!()
      |> Path.join(books_dir)
      |> Path.join("**")
      |> Path.join("*_book.exs")
      |> Path.wildcard()
      |> Enum.map(&Code.require_file/1)
      |> List.flatten()
      |> Enum.each(fn {mod, _} ->
        if Kernel.function_exported?(mod, :run_book, 0) do
          :ets.insert(:datapio_play_books, {mod, false})
        end
      end)
  end

  def run_step(kind, name, opts) do
    :ets.insert(:datapio_play_config, {:current_step, name})
    do_run_step(kind, name, opts)
  end

  defp do_run_step(:shell, name, opts) do
    command = opts |> Keyword.fetch!(:command)
    shell_opts = [
      into: case opts |> Keyword.get(:capture_output, false) do
        true -> ""
        false -> Datapio.Play.StepLogger.new()
      end,
      stderr_to_stdout: true,
      env: opts |> Keyword.get(:environ, [])
    ]

    case System.shell(command, shell_opts) do
      {output, 0} ->
        output

      {%Datapio.Play.StepLogger{}, exit_code} ->
        raise StepFailedError, name: name, info: [exit_code: exit_code]

      {output, exit_code} ->
        raise StepFailedError, name: name, info: [exit_code: exit_code, output: output]
    end
  end

  defp do_run_step({module, function}, name, opts) do
    case apply(module, function, [opts]) do
      :ok ->
        :ok

      {:ok, result} ->
        result

      {:error, reason} ->
        raise StepFailedError, name: name, info: reason
    end
  end
end
