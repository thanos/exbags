defmodule ExBags.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_bags,
      version: "0.1.2",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/thanos/ex_bags",
      homepage_url: "https://github.com/thanos/ex_bags"
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
      {:stream_data, "~> 0.5", only: :test}
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
end
