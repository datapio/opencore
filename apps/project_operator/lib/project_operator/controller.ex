defmodule ProjectOperator.Controller do
  @moduledoc false

  require Logger

  use Datapio.Controller,
    api_version: "datapio.co/v1",
    kind: :project,
    schema: %{
      "$ref" => Application.app_dir(:datapio_project_operator, "priv")
        |> Path.join("project-schema.json")
    }


  @impl true
  def add(%{} = project, _options) do
    Logger.debug("ADDED", [
      name: project["metadata"]["name"],
      namespace: project["metadata"]["namespace"]
    ])
    case with_resource(project, &apply_state/1) do
      {:error, err} ->
        Logger.error("Unexpected error", [error: err])

      _ ->
        :ok
    end
  end

  @impl true
  def modify(%{} = project, _options) do
    Logger.debug("MODIFIED", [
      name: project["metadata"]["name"],
      namespace: project["metadata"]["namespace"]
    ])
    case with_resource(project, &apply_state/1) do
      {:error, err} ->
        Logger.error("Unexpected error", [error: err])

      _ ->
        :ok
    end
  end

  @impl true
  def delete(%{} = project, _options) do
    Logger.debug("DELETED", [
      name: project["metadata"]["name"],
      namespace: project["metadata"]["namespace"]
    ])
    :ok
  end

  @impl true
  def reconcile(%{} = project, _options) do
    Logger.debug("RECONCILE", [
      name: project["metadata"]["name"],
      namespace: project["metadata"]["namespace"]
    ])
    case with_resource(project, &apply_state/1) do
      {:error, err} ->
        Logger.error("Unexpected error", [error: err])

      _ ->
        :ok
    end
    :ok
  end

  defp apply_state(project) do
    desired = desired_state(project)
    observed = observed_state(project)

    errors = []

    errors = errors ++ remove_unwanted(:pipelines, desired, observed)
    errors = errors ++ remove_unwanted(:servers, desired, observed)
    errors = errors ++ remove_unwanted(:templates, desired, observed)
    errors = errors ++ remove_unwanted(:bindings, desired, observed)
    errors = errors ++ remove_unwanted(:event_listeners, desired, observed)
    errors = errors ++ remove_unwanted(:ingresses, desired, observed)

    errors = errors ++ apply_desired(:pipelines, desired, observed)
    errors = errors ++ apply_desired(:servers, desired, observed)
    errors = errors ++ apply_desired(:templates, desired, observed)
    errors = errors ++ apply_desired(:bindings, desired, observed)
    errors = errors ++ apply_desired(:event_listeners, desired, observed)
    errors = errors ++ apply_desired(:ingresses, desired, observed)

    case errors do
      [] -> {:ok, :noresult}
      _ -> {:error, errors}
    end
  end

  @spec desired_state(Datapio.K8s.Resource.t()) :: ProjectOperator.Resources.t()
  defp desired_state(project) do
    ProjectOperator.Resources.from_project(project)
  end

  @spec observed_state(Datapio.K8s.Resource.t()) :: ProjectOperator.Resources.t()
  defp observed_state(project) do
    namespace = project["metadata"]["namespace"]
    get_items = fn
      {:ok, %{"items" => items}} -> items
      _ -> []
    end

    pipelines = K8s.Client.list("tekton.dev/v1alpha1", "Pipeline", namespace: namespace)
      |> run_operation()
      |> then(get_items)
      |> Enum.filter(&Datapio.K8s.Resource.owned?(&1, project))

    servers = K8s.Client.list("datapio.co/v1", "PipelineRunServer", namespace: namespace)
      |> run_operation()
      |> then(get_items)
      |> Enum.filter(&Datapio.K8s.Resource.owned?(&1, project))

    templates = K8s.Client.list("triggers.tekton.dev/v1alpha1", "TriggerTemplate", namespace: namespace)
      |> run_operation()
      |> then(get_items)
      |> Enum.filter(&Datapio.K8s.Resource.owned?(&1, project))

    bindings = K8s.Client.list("triggers.tekton.dev/v1alpha1", "TriggerBinding", namespace: namespace)
      |> run_operation()
      |> then(get_items)
      |> Enum.filter(&Datapio.K8s.Resource.owned?(&1, project))

    event_listeners = K8s.Client.list("triggers.tekton.dev/v1alpha1", "EventListener", namespace: namespace)
      |> run_operation()
      |> then(get_items)
      |> Enum.filter(&Datapio.K8s.Resource.owned?(&1, project))

    ingresses = K8s.Client.list("networking.k8s.io/v1", "Ingress", namespace: namespace)
      |> run_operation()
      |> then(get_items)
      |> Enum.filter(&Datapio.K8s.Resource.owned?(&1, project))

    %{
      pipelines: pipelines,
      servers: servers,
      templates: templates,
      bindings: bindings,
      event_listeners: event_listeners,
      ingresses: ingresses
    }
  end

  @spec remove_unwanted(atom(), ProjectOperator.Resources.t(), ProjectOperator.Resources.t()) :: [term()]
  defp remove_unwanted(kind, desired, observed) do
    observed[kind]
      |> Enum.reduce([], fn resource, operations ->
        is_desired = desired[kind] |> Datapio.K8s.Resource.contains?(resource)

        if is_desired do
          operations
        else
          operations ++ [K8s.Client.delete(resource)]
        end
      end)
      |> run_operations()
      |> Enum.reduce([], fn (result, errors) ->
        case result do
          {:ok, _} -> errors
          {:error, err} -> errors ++ [err]
        end
      end)
  end

  @spec apply_desired(atom(), ProjectOperator.Resources.t(), ProjectOperator.Resources.t()) :: [term()]
  defp apply_desired(kind, desired, observed) do
    desired[kind]
      |> Enum.reduce([], fn (resource, operations) ->
        exists = observed[kind] |> Datapio.K8s.Resource.contains?(resource)

        if exists do
          operations ++ [K8s.Client.update(resource)]
        else
          operations ++ [K8s.Client.create(resource)]
        end
      end)
      |> run_operations()
      |> Enum.reduce([], fn (result, errors) ->
        case result do
          {:ok, _} -> errors
          {:error, err} -> errors ++ [err]
        end
      end)
  end
end
