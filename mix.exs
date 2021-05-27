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
            datapio_core: :permanent,
            datapio_pipelinerun_server: :permanent,
            datapio_project_operator: :permanent
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
          "apps/datapio_pipelinerun_server/README.md": [
            filename: "datapio-pipelinerun-server",
            title: "Datapio PipelineRun Server"
          ],
          "apps/datapio_project_operator/README.md": [
            filename: "datapio-project-operator",
            title: "Datapio Project Operator"
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
      {:ex_doc, git: "https://github.com/linkdd/ex_doc.git", branch: "patch-1", only: :dev, runtime: false}
    ]
  end

  defp documentation_head(:epub), do: ""
  defp documentation_head(:html) do
    """
    <link
      rel="stylesheet"
      href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.23.0/themes/prism.min.css"
      integrity="sha512-tN7Ec6zAFaVSG3TpNAKtk4DOHNpSwKHxxrsiw4GHKESGPs5njn/0sMCUMl2svV4wo4BK/rCP7juYz+zx+l6oeQ=="
      crossorigin="anonymous"
      referrerpolicy="no-referrer"
    />
    <script
      src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.23.0/components/prism-core.min.js"
      integrity="sha512-xR+IAyN+t9EBIOOJw5m83FTVMDsPd63IhJ3ElP4gmfUFnQlX9+eWGLp3P4t3gIjpo2Z1JzqtW/5cjgn+oru3yQ=="
      crossorigin="anonymous" referrerpolicy="no-referrer"
    ></script>
    <script
      src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.23.0/plugins/autoloader/prism-autoloader.min.js"
      integrity="sha512-zc7WDnCM3aom2EziyDIRAtQg1mVXLdILE09Bo+aE1xk0AM2c2cVLfSW9NrxE5tKTX44WBY0Z2HClZ05ur9vB6A=="
      crossorigin="anonymous"
      referrerpolicy="no-referrer"
    ></script>
    """
  end

  defp documentation_body(:epub), do: ""
  defp documentation_body(:html) do
    """
    """
  end
end
