defmodule DatapioTest.Resource do
  use ExUnit.Case

  describe "is_owned()" do
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
end
