defmodule Baud.Mixfile do
  use Mix.Project

  def project do
    [app: :baud,
     version: "0.4.1",
     elixir: "~> 1.3",
     compilers: [:elixir_make | Mix.compilers],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     make_clean: ["clean"],
     aliases: aliases(),
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:modbus]]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.4"},
      {:modbus, "~> 0.2.0"},
      {:ex_doc, "~> 0.12", only: :dev},
    ]
  end

  defp description do
    "Serial port with Modbus support."
  end

  defp package do
    [
     name: :baud,
     files: ["lib", "test", "scripts", "src", "Makefile", "mix.*", "*.exs", ".gitignore", "LICENSE"],
     maintainers: ["Samuel Ventura"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/samuelventura/baud/"}]
  end

  defp aliases do
    [
      "sample1": ["run scripts/sample1.exs"],
      "sample2": ["run scripts/sample2.exs"],
      "modport": ["run scripts/modport.exs"],
    ]
  end
end
