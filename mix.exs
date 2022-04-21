defmodule Baud.Mixfile do
  use Mix.Project

  def project do
    [
      app: :baud,
      version: "0.6.1",
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
    [
      extra_applications: [:sniff, :modbus]
    ]
  end

  defp deps do
    [
      # {:sniff, "~> 0.1.8"},
      # {:sniff, git: "https://github.com/samuelventura/sniff.git", tag: "0.1.8"},
      {:sniff, path: "../sniff"},
      {:modbus, "~> 0.4.0"},
      # {:modbus, git: "https://github.com/samuelventura/modbus.git", tag: "0.4.0"},
      # {:modbus, path: "../modbus"},
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
      long: ["run script/long.exs"],
      slave: ["run script/slave.exs"]
    ]
  end
end
