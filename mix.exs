defmodule MixMinimumElixirVersion.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_minimum_elixir_version,
      version: "0.1.5",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      escript: escript()
    ]
  end

  def application, do: [
    mod: {MixMinimumElixirVersion.Application, []},
    extra_applications: [:req]
  ]

  defp deps do
    [
      {:req, "~> 0.5.0", runtime: true},
      {:decimal, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Mix task to find the minimum Elixir version requirement for a particular project."
  end

  defp package do
    [
      maintainers: ["Douglas Vought"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/voughtdq/mix_minimum_elixir_version"}
    ]
  end

  def escript do
    [main_module: Mix.Tasks.MinimumElixirVersion]
  end
end
