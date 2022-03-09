defmodule LightningGraph.MixProject do
  use Mix.Project

  def project do
    [
      app: :lightning_graph,
      version: "0.1.2",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bolt_sips, "~> 2.0"},
      {:jason, "~> 1.2"}
    ]
  end
end
