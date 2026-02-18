defmodule Notex.MixProject do
  use Mix.Project

  def project do
    [
      app: :notex,
      version: "0.1.1",
      elixir: "~> 1.16",
      name: "Notex",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      source_url: "https://github.com/neodejack/notex",
      homepage_url: "https://hexdocs.pm/notex",
      docs: docs()
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

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        Core: [Notex.Note, Notex.Scale, Notex.ScaleType],
        "Built-in Scale Types": [Notex.ScaleType.Major, Notex.ScaleType.Minor]
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false, warn_if_outdated: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.10", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "It goes like this, the forth, the fifth."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/neodejack/notex"}
    ]
  end
end
