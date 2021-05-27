defmodule DatapioProjectOperator.Resources do
  @moduledoc false

  alias DatapioProjectOperator.Resources, as: Resources

  def from_project(project) do
    %{
      pipelines: [Resources.Pipeline.from_project(project)],
      servers: Resources.PipelineRunServers.from_project(project),
      templates: Resources.TriggerTemplates.from_project(project),
      bindings: [Resources.TriggerBinding.from_project(project)],
      event_listeners: Resources.EventListeners.from_project(project),
      ingresses: [Resources.EventListeners.from_project(project)]
    }
  end
end
