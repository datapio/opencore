defmodule DatapioPipelineRunServer.Exchange.Utilities do
  @moduledoc """
  Utility functions for the scheduler.
  """

  alias Datapio.Dependencies, as: Deps

  def get_rabbitmq_url do
    System.get_env("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
  end

  def connect_to_rabbitmq do
    case Deps.get(:amqp_conn).open(get_rabbitmq_url()) do
      {:ok, connection} -> {:ok, connection}
      {:error, reason} -> {:error, {:connect_to_rabbitmq, reason}}
    end
  end

  def open_channel(connection) do
    case Deps.get(:amqp_channel).open(connection) do
      {:ok, channel} -> {:ok, channel}
      {:error, reason} -> {:error, {:open_channel, reason}}
    end
  end

  def get_exchange_name do
    Application.get_env(
      :datapio_pipelinerun_server,
      :default_exchange,
      "datapio.pipelinerunservers"
    )
  end

  def declare_exchange(channel) do
    resp = channel
      |> Deps.get(:amqp_exchange).declare(get_exchange_name(), :direct)

    case resp do
      :ok -> :ok
      {:error, reason} -> {:error, {:declare_exchange, reason}}
    end
  end

  def declare_queue(channel) do
    resp = channel
      |> Deps.get(:amqp_queue).declare()

    case resp do
      {:ok, %{queue: queue_name}} -> {:ok, queue_name}
      {:error, reason} -> {:error, {:declare_queue, reason}}
    end
  end

  def bind_queue(channel, queue, rk) do
    resp = channel
      |> Deps.get(:amqp_queue).bind(queue, get_exchange_name(), routing_key: rk)

    case resp do
      :ok -> :ok
      {:error, reason} -> {:error, {:bind_queue, reason}}
    end
  end

  def delete_queue(channel, queue) do
    resp = channel
      |> Deps.get(:amqp_queue).delete(queue)

    case resp do
      {:ok, _} -> :ok
      :ok -> :ok
      {:error, reason} -> {:error, {:delete_queue, reason}}
    end
  end

  def start_consumer(channel, queue, consumer_pid) do
    resp = channel
      |> Deps.get(:amqp_basic).consume(get_exchange_name(), queue, consumer_pid)

    case resp do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:start_consumer, reason}}
    end
  end

  def stop_consumer(channel, consumer_tag) do
    resp = channel
      |> Deps.get(:amqp_basic).cancel(consumer_tag)

    case resp do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:stop_consumer, reason}}
    end
  end

  def request_to_json(request) do
    case Jason.encode(request) do
      {:ok, payload} -> {:ok, payload}
      {:error, reason} -> {:error, {:json_encode, reason}}
    end
  end

  def publish_request(channel, routing_key, payload) do
    resp = channel
      |> Deps.get(:amqp_basic).publish(get_exchange_name(), routing_key, payload)

    case resp do
      :ok -> :ok
      {:error, reason} -> {:error, {:publish_request, reason}}
    end
  end
end
