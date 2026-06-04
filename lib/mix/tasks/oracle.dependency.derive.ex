defmodule Mix.Tasks.Oracle.Dependency.Derive do
  use Mix.Task

  alias RmxOSOracle.Dependency

  @shortdoc "Derive M1 dependency-edge JSON"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [output: :string])
    output = Keyword.get(opts, :output, Dependency.default_path())
    Dependency.write!(output)
    Mix.shell().info("oracle.dependency.derive: wrote #{output}")
  end
end
