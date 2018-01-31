defmodule Baud.Mixfile do
  use Mix.Project

  def project do
    [app: :baud,
     version: "0.5.4",
     elixir: "~> 1.3",
     compilers: Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:sniff, git: "https://github.com/samuelventura/sniff.git"},
      {:modbus, "~> 0.3.7"},
      {:ex_doc, "~> 0.12", only: :dev},
    ]
  end

  defp description do
    "Elixir Serial Port with Modbus RTU."
  end

  defp package do
    [
     name: :baud,
     files: ["lib", "test", "script", "*.sh", "mix.*", "*.md", "*.bat", ".gitignore", "LICENSE"],
     maintainers: ["Samuel Ventura"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/samuelventura/baud/"}]
  end

  defp aliases do
    [
      "tryout": ["run script/tryout.exs"],
      "long": ["run script/long.exs"],
      "baud": ["run script/baud.exs"],
      "master": ["run script/master.exs"],
      "modport": ["run script/modport.exs"],
    ]
  end
end
