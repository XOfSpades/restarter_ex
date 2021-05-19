defmodule RestarterEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :restarter_ex,
      version: "0.1.3",
      elixir: ">= 1.5.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Library offering a supervisor with infinite restart functionality and backoff.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Bernhard Stöcker"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/xofspades/restarter_ex"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev, runtime: false}]
  end
end
