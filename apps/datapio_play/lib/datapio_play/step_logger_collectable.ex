defimpl Collectable, for: Datapio.Play.StepLogger do
  def into(logger) do
    collector_fun = fn
      acc, {:cont, elem} ->
        logger |> Datapio.Play.StepLogger.print(elem)
        acc

      acc, :done ->
        acc

      _, :halt ->
        :ok
    end

    initial_acc = logger
    {initial_acc, collector_fun}
  end
end