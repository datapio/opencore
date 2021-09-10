defmodule DatapioOpencore.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      releases: [
        datapio: [
          applications: [
            datapio_cluster: :permanent,
            datapio_mq: :permanent,
            pipelinerun_server: :permanent,
            project_operator: :permanent
          ]
        ]
      ],

      # Docs
      name: "Datapio OpenCore",
      source_url: "https://github.com/datapio/opencore",
      homepage_url: "https://opencore.datapio.co",
      docs: [
        main: "datapio-opencore",
        markdown_processor: {
          ExDoc.Markdown.Earmark,
          [code_class_prefix: "language-"]
        },
        before_closing_head_tag: &documentation_head/1,
        before_closing_body_tag: &documentation_body/1,
        extras: [
          "README.md": [
            filename: "datapio-opencore",
            title: "Datapio OpenCore"
          ],
          "apps/datapio_play/README.md": [
            filename: "datapio-play",
            title: "Datapio Play"
          ],
          "apps/datapio_mq/README.md": [
            filename: "datapio-mq",
            title: "Datapio Message Queue"
          ],
          "apps/datapio_cluster/README.md": [
            filename: "datapio-cluster",
            title: "Datapio Cluster"
          ],
          "apps/datapio_k8s/README.md": [
            filename: "datapio-k8s",
            title: "Datapio K8s"
          ],
          "apps/datapio_controller/README.md": [
            filename: "datapio-controller",
            title: "Datapio Controller"
          ],
          "apps/pipelinerun_server/README.md": [
            filename: "pipelinerun-server",
            title: "PipelineRun Server"
          ],
          "apps/project_operator/README.md": [
            filename: "project-operator",
            title: "Project Operator"
          ]
        ],
        groups_for_extras: [
          "Introduction": Path.wildcard("**/README.md"),
          "Guides": Path.wildcard("guides/*.md")
        ]
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},        # Documentation
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}  # Static Analysis
    ]
  end

  defp documentation_head(:epub), do: ""
  defp documentation_head(:html) do
    """
    <link rel="stylesheet" href="https://cdn.link-society.com/css/prism/1.24.1/prism-light.css" />
    <link rel="stylesheet" href="https://cdn.link-society.com/css/prism/1.24.1/prism-dark.css" />
    <script
      src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.24.1/components/prism-core.min.js"
      crossorigin="anonymous"
      referrerpolicy="no-referrer"
      defer
    ></script>
    <script
      src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.24.1/plugins/autoloader/prism-autoloader.min.js"
      crossorigin="anonymous"
      referrerpolicy="no-referrer"
      defer
    ></script>
    """
  end

  defp documentation_body(:epub), do: ""
  defp documentation_body(:html) do
    """
    """
  end
end
