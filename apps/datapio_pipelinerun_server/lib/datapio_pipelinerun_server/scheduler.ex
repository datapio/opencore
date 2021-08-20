defmodule DatapioPipelinerunServer.Scheduler do
  defp rabbitmq_url do
    System.get_env("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
  end
end
