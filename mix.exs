defmodule MixMinimumElixirVersion.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_minimum_elixir_version,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application, do: []

  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.24", only: :docs, runtime: false}
    ]
  end
end
