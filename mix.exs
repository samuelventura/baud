defmodule Mix.Tasks.Compile.Nif do
  def run(_) do
    case :os.type() do
      {:unix, :darwin} -> 0 = Mix.Shell.IO.cmd("make -f make.posix")
      {:unix, :linux} -> 0 = Mix.Shell.IO.cmd("make -f make.posix")
      {:win32, :nt} -> 0 = Mix.Shell.IO.cmd("build")
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
      {:modbus, "~> 0.3.4"},
      {:ex_doc, "~> 0.12", only: :dev},
    ]
  end

  defp description do
    "Elixir Serial Port with Modbus RTU."
  end

  defp package do
    [
     name: :baud,
     files: ["lib", "test", "script", "src", "make.*", "*.bat", "mix.*", "*.exs", ".gitignore", "LICENSE"],
     maintainers: ["Samuel Ventura"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/samuelventura/baud/"}]
  end

  defp aliases do
    [
      "baud": ["run script/baud.exs"],
      "rtu": ["run script/rtu.exs"],
      "modport": ["run script/modport.exs"],
    ]
  end
end
