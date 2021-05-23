defmodule DatapioProjectOperator.Resources do
  @moduledoc false

  alias DatapioProjectOperator.Resources, as: Resources

  def from_project(project) do
    pipeline = Resources.Pipeline.from_project(project)
    servers = Resources.PipelineRunServers.from_project(project)
    templates = Resources.TriggerTemplates.from_project(project)
    binding = Resources.TriggerBinding.from_project(project)
    event_listeners = Resources.EventListeners.from_project(project)
    ingress = Resources.EventListeners.from_project(project)

    [pipeline] ++ servers ++ templates ++ [binding] ++ event_listeners ++ ingress
  end
end
