defmodule Baud.Mixfile do
  use Mix.Project

  def project do
    [
      app: :baud,
      version: "0.5.6",
      elixir: "~> 1.3",
      compilers: Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:sniff, :modbus]]
  end

  defp deps do
    [
      {:sniff, "~> 0.1.7"},
      {:modbus, "~> 0.3.9"},
      {:ex_doc, "~> 0.28", only: :dev}
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
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/samuelventura/baud/"}
    ]
  end

  defp aliases do
    [
      baud: ["run script/baud.exs"],
      long: ["run script/long.exs"]
    ]
  end
end
