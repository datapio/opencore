defmodule DatapioMock.K8s.Conn do
  @moduledoc false

  def from_service_account do
    {:ok, [kind: :service_account]}
  end

  def from_file(path) do
    {:ok, [kind: :file, path: path]}
  end
end
