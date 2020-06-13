defmodule OT.Mixfile do
  use Mix.Project

  @version "0.1.1"
  @github_url "https://github.com/codesandbox/ot_ex"

  def project do
    [
      app: :ot_ex,
      version: @version,
      description: description(),
      package: package(),
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [flags: ~w(-Werror_handling
                          -Wrace_conditions
                          -Wunderspecs
                          -Wunmatched_returns)],

      # Docs
      name: "OT",
      homepage_url: @github_url,
      source_url: @github_url,
      docs: docs(),
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: [rust_ot: []]
    ]
  end

  defp aliases do
    [lint: ["credo", "dialyzer --halt-exit-status"]]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.14", only: [:dev]},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:benchee, "~> 1.0", only: [:dev, :test]},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test]},
      {:iconv, "~> 1.0.10"},
      {:rustler, github: "rusterlium/rustler", ref: "e343b8ca", sparse: "rustler_mix"}
    ]
  end

  defp description do
    """
    OT provides libraries for operational transformation, which is a method of
    achieving consistency in a collaborative software system.
    """
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      extras: [
        "README.md": [filename: "README.md", title: "Readme"],
        "LICENSE.md": [filename: "LICENSE.md", title: "License"]
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Jonathan Clem <jonathan@jclem.net>"],
      licenses: ["ISC"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
