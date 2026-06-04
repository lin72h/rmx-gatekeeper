defmodule Mix.Tasks.Oracle.Dependency.Audit do
  use Mix.Task

  alias RmxOSOracle.CanonicalJSON
  alias RmxOSOracle.Dependency

  @shortdoc "Validate derived dependency-edge JSON"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [path: :string, format: :string])
    path = Keyword.get(opts, :path, Dependency.default_path())
    report = Dependency.audit(path)

    if Keyword.get(opts, :format, "text") == "json" do
      Mix.shell().info(CanonicalJSON.encode!(report))
    else
      Mix.shell().info("oracle.dependency.audit: #{report["status"]}")
      Mix.shell().info("  path: #{report["path"]}")
      Mix.shell().info("  edges: #{report["edge_count"]}")

      Enum.each(report["errors"], fn error ->
        Mix.shell().error("  failure: #{error}")
      end)
    end

    if report["status"] != "pass", do: exit({:shutdown, 1})
  end
end
