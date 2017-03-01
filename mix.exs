defmodule Mix.Tasks.Compile.Nif do
  def run(_) do
    case :os.type() do
      {:unix, :darwin} -> 0 = Mix.Shell.IO.cmd("make")
      {:unix, :linux} -> 0 = Mix.Shell.IO.cmd("make")
      {:win32, :nt} -> nil #0 = Mix.Shell.IO.cmd("build")
    end
    :ok
  end
end

defmodule Baud.Mixfile do
  use Mix.Project

  def project do
    [app: :baud,
     version: "0.5.0",
     elixir: "~> 1.3",
     compilers: [:nif | Mix.compilers],
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
    ]
  end

  defp description do
    "Elixir Serial Port with Modbus RTU."
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
      "sample": ["run scripts/sample.exs"],
    ]
  end
end
