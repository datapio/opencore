defmodule DatapioTest.Resource do
  use ExUnit.Case

  describe "is_owned/2" do
    test "should return true if there is an ownerReference" do
      resource = %{
        "metadata" => %{
          "ownerReferences" => [
            %{
              "apiVersion" => "v1",
              "kind" => "Example",
              "name" => "foo",
              "uid" => "UUID"
            }
          ]
        }
      }
      owner = %{
        "apiVersion" => "v1",
        "kind" => "Example",
        "metadata" => %{
          "name" => "foo",
          "uid" => "UUID"
        }
      }

      assert Datapio.Resource.is_owned(resource, owner) == true
    end

    test "should return false if there is no ownerReferences" do
      resource = %{
        "metadata" => %{
          "ownerReferences" => []
        }
      }
      owner = %{
        "apiVersion" => "v1",
        "kind" => "Example",
        "metadata" => %{
          "name" => "foo",
          "uid" => "UUID"
        }
      }

      assert Datapio.Resource.is_owned(resource, owner) == false
    end

    test "should raise an error if the owner resource has no UID" do
      resource = %{
        "metadata" => %{
          "ownerReferences" => []
        }
      }
      owner = %{
        "apiVersion" => "v1",
        "kind" => "Example",
        "metadata" => %{
          "name" => "foo"
        }
      }

      assert_raise JsonXema.ValidationError, fn ->
        Datapio.Resource.is_owned(resource, owner)
      end
    end
  end

  describe "list_contains/2" do
    test "should return true if a resource with the same uid is found" do
      resource = %{"metadata" => %{"uid" => "u1"}}
      collection = [
        %{"metadata" => %{"uid" => "u1"}},
        %{"metadata" => %{"uid" => "u2"}}
      ]

      assert Datapio.Resource.list_contains(resource, collection) == true
    end

    test "should return true if no resource with the same uid is found" do
      resource = %{"metadata" => %{"uid" => "u3"}}
      collection = [
        %{"metadata" => %{"uid" => "u1"}},
        %{"metadata" => %{"uid" => "u2"}}
      ]

      assert Datapio.Resource.list_contains(resource, collection) == false
    end

    test "should raise an exception if the resources do not have a uid" do
      resource = %{}
      collection = [
        %{"metadata" => %{"uid" => "u1"}},
        %{"metadata" => %{"uid" => "u2"}}
      ]

      assert_raise JsonXema.ValidationError, fn ->
        Datapio.Resource.list_contains(resource, collection)
      end

      resource = %{"metadata" => %{"uid" => "u1"}}
      collection = [
        %{},
        %{"metadata" => %{"uid" => "u2"}}
      ]

      assert_raise JsonXema.ValidationError, fn ->
        Datapio.Resource.list_contains(resource, collection)
      end
    end
  end
end
