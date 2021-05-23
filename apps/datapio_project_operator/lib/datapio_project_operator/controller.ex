defmodule DatapioProjectOperator.Controller do
  @moduledoc """
  Describe a Datapio Project
  """
  use Bonny.Controller
  alias DatapioProjectOperator.Resources, as: Resources

  @group "datapio.co"
  @version "v1"

  @scope :namespaced
  @names %{
    plural: "projects",
    singular: "project",
    kind: "Project",
    shortNames: [
      "proj"
    ]
  }

  @doc """
  Handles an `ADDED` event
  """
  @spec add(map()) :: :ok | :error
  @impl Bonny.Controller
  def add(%{} = project) do
    desired_resources = Resources.from_project(project)
    # TODO: kubectl apply
    :ok
  end

  @doc """
  Handles a `MODIFIED` event
  """
  @spec modify(map()) :: :ok | :error
  @impl Bonny.Controller
  def modify(%{} = project) do
    reconcile(project)
  end

  @doc """
  Handles a `DELETED` event.

  Since we set the 'ownerReferences' metadata, Kubernetes will automatically
  remove child resources.
  """
  @spec delete(map()) :: :ok | :error
  @impl Bonny.Controller
  def delete(%{} = project) do
    :ok
  end

  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @spec reconcile(map()) :: :ok | :error
  @impl Bonny.Controller
  def reconcile(%{} = project) do
    desired_resources = Resources.from_project(project)
    # TODO: kubectl get by ownerReferences
    # TODO: kubectl apply
    # TODO: kubectl delete old
    :ok
  end
end
