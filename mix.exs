defmodule Elxlog.MixProject do
  use Mix.Project

  def project do
    [
      app: :elxlog,
      version: "0.1.5",
      elixir: "~> 1.4",
      description: "Prolog interpreter/compiler in Elixir",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "Elxlog",
      source_url: "https://github.com/sasagawa888/Elxlog",
      start_permanent: Mix.env() == :prod,
      docs: [
        # The main page in the docs
        # main: "Elxlog",
        extras: ["README.md"]
      ],
      package: [
        files: [
          "lib",
          "README.md",
          "mix.exs",
          "queens.pl",
          "queens1.pl",
          "test.pl"
        ],
        maintainers: ["Kenichi Sasagawa"],
        licenses: ["modified BSD"],
        links: %{"GitHub" => "https://github.com/sasagawa888/Elxlog"}
      ]
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
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
