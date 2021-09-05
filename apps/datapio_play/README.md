# Datapio.Play

[Ansible](https://ansible.com)-inspired task runner.

## 🔎 What is it?

This project provides a simple way to run a list of tasks and stop at the first
failure. Common use cases are:

 - 🚀 Deployment
 - 🧪 End-To-End testing
 - 🔧 Configuration Management
 - ...

## 📦 Installation

This package can be installed by adding `datapio_play` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:datapio_core,
      github: "datapio/opencore",
      ref: "main",
      sparse: "apps/datapio_play"
    }
  ]
end
```

## 👨🏻‍🏫 Usage

In your Mix project, add a folder named `e2e`.

In a file named `example_book.exs`, add the following:

```elixir
defmodule MyProject.E2E.Example do
  use Datapio.Play.DSL

  book "My first book" do
    task "My first task" do
      # Basic call to Shell command
      step :my_first_step,
        uses: :shell,
        with: [
          command: "echo Hello world"
        ]

      # Shell output can be captured
      "Hello world\n" = step :my_second_task,
        uses: :shell,
        with: [
          command: "echo $MSG",
          capture_output: true,
          env: [
            {"MSG", "Hello world"}
          ]
        ]
    end
  end
```

Then, in a file named `main.exs`, add the following

```elixir
use Datapio.Play,
  books_dir: "e2e"  # defaults to "playbooks"

play do
  run MyProject.E2E.Example
rescue
  task "In case of failure" do
    step :show_message,
      uses: :shell,
      with: [
        command: "echo Oops"
      ]
  end
end
```

Now, you can run your playbooks with the following command:

```
$ mix run --no-start ./e2e/main.exs
===[ My first book ]===
:: My first task
Hello world
```

## ⚗️ More examples

For now, only the `:shell` task can be used. If you need more, you can write
your own steps:

```elixir
defmodule MyProject.Steps do
  def greetings(name: name) do
    IO.puts("Hello #{name}")
    :ok
  end

  def inverse(number: x) do
    if x != 0 do
      {:ok, 1 / x}
    else
      {:error, :division_by_zero}
    end
  end
end

defmodule MyProject.MyBook do
  use Datapio.Play.DSL

  book "Advanced example" do
    task "Greets people" do
      step :bob,
        uses: {MyProject.Steps, :greetings},
        with: [name: :bob]

      step :alice,
        uses: {MyProject.Steps, :greetings},
        with: [name: :alice]
    end

    task "Do some math" do
      0.5 = step :half,
        uses: {MyProject.Steps, :inverse},
        with: [number: 2]

      :not_reached = step :will_fail,
        uses: {MyProject.Steps, :inverse},
        with: [number: 0]
    end
  end
end
```
