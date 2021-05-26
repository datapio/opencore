defmodule Datapio.Resource do
  use Norm

  defp conform_owner_resource(%{} = owner) do
    try do
      {:ok, conform!(owner, schema(%{
        "apiVersion" => spec(is_binary() and &(String.length(&1) > 0)),
        "kind" => spec(is_binary() and &(String.length(&1) > 0)),
        "metadata" => schema(%{
          "name" => spec(is_binary() and &(String.length(&1) > 0)),
          "uid" => spec(is_binary() and &(String.length(&1) > 0))
        })
      }))}
    rescue
      err -> {:error, {:owner, err}}
    end
  end

  defp conform_owned_resource(%{} = resource, %{} = owner) do
    try do
      {:ok, conform!(resource, schema(%{
        "metadata" => schema(%{
          "ownerReferences" => coll_of(schema(%{
            "apiVersion" => spec(is_binary() and &(owner["apiVersion"] == &1)),
            "kind" => spec(is_binary() and &(owner["kind"] == &1)),
            "name" => spec(is_binary() and &(owner["metadata"]["name"] == &1)),
            "uid" => spec(is_binary() and &(owner["metadata"]["uid"] == &1))
          }))
        })
      }))}
    rescue
      err -> {:error, {:owned, err}}
    end
  end

  def is_owned(%{} = resource, %{} = owner) do
    with {:ok, owner} <- conform_owner_resource(owner),
         {:ok, resource} <- conform_owned_resource(resource, owner)
    do
      true
    else
      {:error, {:owner, err}} ->
        raise err

      _ ->
        false
    end
  end

  def list_contains(%{} = resource, items) do
    resource_schema = schema(%{
      "metadata" => schema(%{
        "uid" => spec(is_binary() and &(String.length(&1) > 0))
      })
    })

    resource = conform!(resource, resource_schema)

    conform!(items, coll_of(resource_schema))
      |> Stream.filter(fn item -> item["metadata"]["uid"] == resource["metadata"]["uid"] end)
      |> Enum.count()
      |> (fn i -> i > 0 end).()
  end
end
