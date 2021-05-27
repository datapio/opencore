defmodule Datapio.Resource do
  defp validate_owner_resource(%{} = owner) do
    schema = %{
      "type" => "object",
      "required" => ["apiVersion", "kind", "metadata"],
      "properties" => %{
        "apiVersion" => %{ "type" => "string", "minLength" => 1},
        "kind" => %{ "type" => "string", "minLength" => 1},
        "metadata" => %{
          "type" => "object",
          "required" => ["name", "uid"],
          "properties" => %{
            "name" => %{ "type" => "string", "minLength" => 1},
            "uid" => %{ "type" => "string", "minLength" => 1}
          }
        }
      }
    } |> JsonXema.new()

    with :ok <- JsonXema.validate(schema, owner)
    do
      :ok
    else
      {:error, err} -> {:error, {:owner, err}}
    end
  end

  defp validate_owned_resource(%{} = resource, %{}) do
    schema = %{
      "type" => "object",
      "required" => ["metadata"],
      "properties" => %{
        "metadata" => %{
          "type" => "object",
          "properties" => %{
            "ownerReferences" => %{
              "type" => "array",
              "default" => [],
              "items" => %{
                "type" => "object",
                "required" => ["apiVersion", "kind", "name", "uid"],
                "properties" => %{
                  "apiVersion" => %{ "type" => "string", "minLength" => 1},
                  "kind" => %{ "type" => "string", "minLength" => 1},
                  "name" => %{ "type" => "string", "minLength" => 1},
                  "uid" => %{ "type" => "string", "minLength" => 1}
                }
              }
            }
          }
        }
      }
    } |> JsonXema.new()

    with :ok <- JsonXema.validate(schema, resource)
    do
      :ok
    else
      {:error, err} -> {:error, {:owned, err}}
    end
  end

  def is_owned(%{} = resource, %{} = owner) do
    with :ok <- validate_owner_resource(owner),
         :ok <- validate_owned_resource(resource, owner)
    do
      resource["metadata"]["ownerReferences"]
        |> Stream.filter(fn ref ->
          ref["apiVersion"] == owner["apiVersion"] and \
          ref["kind"] == owner["kind"] and \
          ref["name"] == owner["metadata"]["name"] and \
          ref["uid"] == owner["metadata"]["uid"]
        end)
        |> Enum.count()
        |> (fn i -> i > 0 end).()
    else
      {:error, {:owner, err}} ->
        raise err

      _ ->
        false
    end
  end

  def list_contains(%{} = resource, items) do
    resource_schema = %{
      "type" => "object",
      "required" => ["metadata"],
      "properties" => %{
        "metadata" => %{
          "type" => "object",
          "required" => ["uid"],
          "properties" => %{
            "uid" => %{ "type" => "string", "minLength" => 1}
          }
        }
      }
    }
    collection_schema = %{
      "type" => "array",
      "items" => resource_schema
    }

    :ok = resource_schema
       |> JsonXema.new()
       |> JsonXema.validate!(resource)

    :ok = collection_schema
      |> JsonXema.new()
      |> JsonXema.validate!(items)

    items
      |> Stream.filter(fn item -> item["metadata"]["uid"] == resource["metadata"]["uid"] end)
      |> Enum.count()
      |> (fn i -> i > 0 end).()
  end
end
