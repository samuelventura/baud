defmodule Mix.Tasks.Compile.Native do
  @shortdoc "Compiles native code"
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
     version: "0.3.0",
     elixir: "~> 1.3",
     compilers: [:native, :elixir, :app],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    []
  end

  defp deps do
    [
      {:modbus, git: "https://github.com/samuelventura/modbus.git"},
      {:ex_doc, "~> 0.12", only: :dev},
    ]
  end

  defp description do
    """
    Serial port with RTU and TCP-to-RTU support.
    """
  end

  defp package do
    [
     name: :baud,
     files: ["lib", "test", "src", "Makefile", "mix.exs", "*.md", ".gitignore"],
     maintainers: ["Samuel Ventura"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/samuelventura/baud/",
              "Docs" => "http://samuelventura.github.io/baud/"}]
  end
end
