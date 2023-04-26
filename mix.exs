defmodule EctoQuerify.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_querify,
      version: "0.0.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "EctoQuerify",
      source_url: "https://github.com/bmarkons/ecto_querify",
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: application_mod(Mix.env())
    ]
  end

  def application_mod(:test), do: {EctoQuerify.TestApplication, []}
  def application_mod(_), do: nil

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.9", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    EctoQuerify is a library that brings your schemas queries they need.
    """
  end

  defp package do
    [
      files: ~w(lib mix.exs README* LICENSE* CHANGELOG*),
      maintainers: ["@bmarkons"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bmarkons/ecto_querify"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
