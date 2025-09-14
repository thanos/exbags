defmodule ExBags.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_bags,
      version: "0.2.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/thanos/ex_bags",
      homepage_url: "https://github.com/thanos/ex_bags",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
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
  defp deps do
    [
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:stream_data, "~> 0.5", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp description do
    "Enhanced map operations for Elixir with set-like functions including intersection, difference, symmetric difference, and reconciliation."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["thanos vassilakis"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/thanos/ex_bags"
      }
    ]
  end

  # Custom mix tasks
  defp aliases do
    [
      benchmark: "run priv/scripts/benchmarks.exs",
      "benchmark.intersect": "run priv/scripts/intersect_benchmark.exs",
      "benchmark.stream": "run priv/scripts/stream_benchmark.exs",
      "benchmark.all": "run priv/scripts/run_benchmarks.exs"
    ]
  end
end
