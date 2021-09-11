defmodule Datapio.K8s.Resource do
  @moduledoc """
  Utility functions to manipulate Kubernetes resources.
  """

  @typedoc "Represent a Kubernetes resource"
  @type resource :: map()
  @type t :: resource()

  @typedoc "Represent a JSON Schema"
  @type schema :: map()

  @doc "Validate a resource (or a collection of resource) against a schema"
  @spec validate(resource() | [resource()], schema()) :: :ok | {:error, term()}
  def validate(data, schema) do
    schema
      |> JsonXema.new(loader: Datapio.K8s.SchemaLoader)
      |> JsonXema.validate(data)
  end

  @doc "Check if the resource is owned by another resource."
  @spec owned?(resource(), resource()) :: boolean()
  def owned?(resource, owner) do
    owner_schema = get_schema("owner-resource-schema.json")
    owned_schema = get_schema("owned-resource-schema.json")

    with {:owner, :ok} <- {:owner, validate(owner, owner_schema)},
         {:owned, :ok} <- {:owned, validate(resource, owned_schema)}
    do
      resource["metadata"]
        |> Map.get("ownerReferences", [])
        |> Stream.filter(fn ref -> ref["apiVersion"] == owner["apiVersion"] end)
        |> Stream.filter(fn ref -> ref["kind"] == owner["kind"] end)
        |> Stream.filter(fn ref -> ref["name"] == owner["metadata"]["name"] end)
        |> Stream.filter(fn ref -> ref["uid"] == owner["metadata"]["uid"] end)
        |> Enum.count()
        |> then(&(&1 > 0))
    else
      {domain, {:error, reason}} ->
        raise "#{domain} validation failed: #{Exception.message(reason)}"

      _ ->
        false
    end
  end

  @doc "Add a resource as owner to another resource"
  @spec has_owner(resource(), resource()) :: resource()
  def has_owner(resource, new_owner) do
    case owned?(resource, new_owner) do
      true ->
        resource

      false ->
        new_ref = %{
          "apiVersion" => new_owner["apiVersion"],
          "kind" => new_owner["kind"],
          "name" => new_owner["metadata"]["name"],
          "uid" => new_owner["metadata"]["uid"]
        }

        meta = resource["metadata"]
        refs = meta |> Map.get("ownerReferences", [])
        new_meta = meta |> Map.merge(%{"ownerReferences" => [new_ref | refs]})
        resource |> Map.merge(%{"metadata" => new_meta})
    end
  end

  @doc "Check if a resource is present in a collection of resource"
  @spec contains?([resource()], resource()) :: boolean()
  def contains?(items, resource) do
    resource_schema = get_schema("persisted-resource-schema.json")
    collection_schema = get_schema("collection-schema.json")

    with {:resource, :ok} <- {:resource, validate(resource, resource_schema)},
         {:collection, :ok} <- {:collection, validate(items, collection_schema)}
    do
      items
        |> Stream.filter(fn item -> item["metadata"]["uid"] == resource["metadata"]["uid"] end)
        |> Enum.count()
        |> then(&(&1 > 0))
    else
      {domain, {:error, reason}} ->
        raise "#{domain} validation failed: #{Exception.message(reason)}"

      _ ->
        false
    end
  end

  defp get_schema(path) do
    priv_dir = Application.app_dir(:datapio_k8s, "priv")
    %{"$ref" => priv_dir |> Path.join(path)}
  end
end
