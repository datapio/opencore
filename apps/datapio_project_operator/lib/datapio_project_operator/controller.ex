defmodule DatapioProjectOperator.Controller do
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
  def add(%{} = project) do
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
  def modify(%{} = project) do
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
  def delete(%{} = project) do
    Logger.debug("DELETED", [
      name: project["metadata"]["name"],
      namespace: project["metadata"]["namespace"]
    ])
    :ok
  end

  @impl true
  def reconcile(%{} = project) do
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

  defp desired_state(project) do
    DatapioProjectOperator.Resources.from_project(project)
  end

  defp observed_state(project) do
    namespace = project["metadata"]["namespace"]
    get_items = fn {:ok, %{ "items" => items }} -> items end

    pipelines = K8s.Client.list("tekton.dev/v1alpha1", "Pipeline", namespace: namespace)
      |> run_operation()
      |> get_items.()
      |> Enum.filter(&Datapio.Resource.is_owned(&1, project))

    servers = K8s.Client.list("datapio.co/v1", "PipelineRunServer", namespace: namespace)
      |> run_operation()
      |> get_items.()
      |> Enum.filter(&Datapio.Resource.is_owned(&1, project))

    templates = K8s.Client.list("triggers.tekton.dev/v1alpha1", "TriggerTemplate", namespace: namespace)
      |> run_operation()
      |> get_items.()
      |> Enum.filter(&Datapio.Resource.is_owned(&1, project))

    bindings = K8s.Client.list("triggers.tekton.dev/v1alpha1", "TriggerBinding", namespace: namespace)
      |> run_operation()
      |> get_items.()
      |> Enum.filter(&Datapio.Resource.is_owned(&1, project))

    event_listeners = K8s.Client.list("triggers.tekton.dev/v1alpha1", "EventListener", namespace: namespace)
      |> run_operation()
      |> get_items.()
      |> Enum.filter(&Datapio.Resource.is_owned(&1, project))

    ingresses = K8s.Client.list("networking.k8s.io/v1", "Ingress", namespace: namespace)
      |> run_operation()
      |> get_items.()
      |> Enum.filter(&Datapio.Resource.is_owned(&1, project))

    %{
      pipelines: pipelines,
      servers: servers,
      templates: templates,
      bindings: bindings,
      event_listeners: event_listeners,
      ingresses: ingresses
    }
  end

  defp remove_unwanted(kind, desired, observed) do
    observed[kind]
      |> Enum.map_reduce([], fn (resource, operations) ->
        is_desired = resource |> Datapio.Resource.list_contains(desired[kind])

        if not is_desired do
          operations ++ [K8s.Client.delete(resource)]
        else
          operations
        end
      end)
      |> run_operations()
      |> Enum.map_reduce([], fn (result, errors) ->
        case result do
          {:ok, _} -> errors
          {:error, err} -> errors ++ [err]
        end
      end)
  end

  defp apply_desired(kind, desired, observed) do
    desired[kind]
      |> Enum.map_reduce([], fn (resource, operations) ->
        exists = resource |> Datapio.Resource.list_contains(observed[kind])

        if exists do
          operations ++ [K8s.Client.update(resource)]
        else
          operations ++ [K8s.Client.create(resource)]
        end
      end)
      |> run_operations()
      |> Enum.map_reduce([], fn (result, errors) ->
        case result do
          {:ok, _} -> errors
          {:error, err} -> errors ++ [err]
        end
      end)
  end
end
