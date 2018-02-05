defmodule LifeBeyondApocalypse.Mixfile do
  use Mix.Project

  def project do
    [
      app: :life_beyond_apocalypse,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      escript: escript(),
    ]
  end

  defp escript do
    [main_module: LifeBeyondApocalypse.CLI]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LifeBeyondApocalypse.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
            {:poison, "~> 3.1"},
            {:faker, "~> 0.9.0"},
    ]
  end
end
