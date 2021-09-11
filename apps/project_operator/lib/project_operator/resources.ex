defmodule ProjectOperator.Resources do
  @moduledoc false

  alias ProjectOperator.Resources, as: Resources

  @type t :: %{
    pipelines: [Datapio.K8s.Resource.t()],
    servers: [Datapio.K8s.Resource.t()],
    templates: [Datapio.K8s.Resource.t()],
    bindings: [Datapio.K8s.Resource.t()],
    event_listeners: [Datapio.K8s.Resource.t()],
    ingresses: [Datapio.K8s.Resource.t()]
  }

  @spec from_project(Datapio.K8s.Resource.t()) :: t()
  def from_project(project) do
    %{
      pipelines: Resources.Pipeline.from_project(project),
      servers: Resources.PipelineRunServers.from_project(project),
      templates: Resources.TriggerTemplates.from_project(project),
      bindings: Resources.TriggerBinding.from_project(project),
      event_listeners: Resources.EventListeners.from_project(project),
      ingresses: Resources.EventListeners.from_project(project)
    }
  end
end
