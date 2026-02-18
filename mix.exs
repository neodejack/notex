defmodule Notex.MixProject do
  use Mix.Project

  def project do
    [
      app: :notex,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        # ignore TODO/FIXME comment checks
        "credo --strict --ignore-checks Design.Tag",
        "cmd env MIX_ENV=test mix test",
        "dialyzer"
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.10", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
