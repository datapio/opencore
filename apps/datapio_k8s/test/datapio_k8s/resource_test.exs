defmodule Datapio.Test.K8s.Resource do
  use ExUnit.Case

  @schema %{"type" => "object"}

  @owner %{
    "apiVersion" => "example.com/v1",
    "kind" => "Example",
    "metadata" => %{
      "name" => "owner",
      "uid" => "UUID"
    }
  }
  @owned %{
    "apiVersion" => "example.com/v1",
    "kind" => "Example",
    "metadata" => %{
      "ownerReferences" => [
        %{
          "apiVersion" => "example.com/v1",
          "kind" => "Example",
          "name" => "owner",
          "uid" => "UUID"
        }
      ]
    }
  }
  @not_owned %{
    "apiVersion" => "example.com/v1",
    "kind" => "Example",
    "metadata" => %{}
  }

  describe "validate/2" do
    test "success" do
      assert :ok == Datapio.K8s.Resource.validate(%{}, @schema)
    end

    test "failure" do
      case Datapio.K8s.Resource.validate(:wrong, @schema) do
        :ok ->
          assert false, "should not validate :wrong"

        {:error, %JsonXema.ValidationError{}} ->
          assert true
      end
    end
  end

  describe "owned?/2" do
    test "invalid resource" do
      assert_raise RuntimeError, ~r/^owned validation failed/, fn ->
        Datapio.K8s.Resource.owned?(%{}, @owner)
      end

      assert_raise RuntimeError, ~r/^owner validation failed/, fn ->
        Datapio.K8s.Resource.owned?(@owned, %{})
      end
    end

    test "success" do
      assert true == Datapio.K8s.Resource.owned?(@owned, @owner)
      assert false == Datapio.K8s.Resource.owned?(@not_owned, @owner)
    end
  end

  describe "has_owner/2" do
    test "already owned" do
      assert @owned == @owned |> Datapio.K8s.Resource.has_owner(@owner)
    end

    test "was not owned" do
      assert @owned == @not_owned |> Datapio.K8s.Resource.has_owner(@owner)
    end
  end

  describe "contains?/2" do
    test "validation failed" do
      assert_raise RuntimeError, ~r/resource validation failed/, fn ->
        Datapio.K8s.Resource.contains?([], %{})
      end

      assert_raise RuntimeError, ~r/collection validation failed/, fn ->
        Datapio.K8s.Resource.contains?(:wrong, @owner)
      end
    end

    test "does contain the resource" do
      assert true == Datapio.K8s.Resource.contains?([@owner], @owner)
    end

    test "does not contain the resource" do
      assert false == Datapio.K8s.Resource.contains?([], @owner)
    end
  end
end