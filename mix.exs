defmodule Mix.Tasks.Compile.Native do
  def run(_) do
    0 = Mix.Shell.IO.cmd("make")
    Mix.Project.build_structure
    :ok
  end
end

defmodule Baud.Mixfile do
  use Mix.Project

  def project do
    [app: :baud,
     version: "0.4.2",
     elixir: "~> 1.3",
     compilers: [:native, :elixir, :app],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
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
      {:modbus, "~> 0.3.0"},
      {:ex_doc, "~> 0.12", only: :dev},
    ]
  end

  defp description do
    "Serial Port with Modbus support."
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
