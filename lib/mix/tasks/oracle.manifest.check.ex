defmodule Mix.Tasks.Oracle.Manifest.Check do
  use Mix.Task

  alias RmxOSOracle.CanonicalJSON
  alias RmxOSOracle.Manifest

  @shortdoc "Validate the accepted M0 legacy source manifest"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          source: :string,
          expected_sha: :string,
          manifest: :string,
          mode: :string,
          format: :string
        ]
      )

    source = Keyword.get(opts, :source, Manifest.default_source())
    manifest_path = Keyword.get(opts, :manifest, Manifest.default_manifest_path())
    expected_sha = Keyword.get(opts, :expected_sha, Manifest.expected_digest())
    mode = Keyword.get(opts, :mode, "committed")
    format = Keyword.get(opts, :format, "text")

    report = Manifest.check(source, manifest_path, expected_sha, mode)

    if format == "json" do
      Mix.shell().info(CanonicalJSON.encode!(report))
    else
      Mix.shell().info("oracle.manifest.check: #{report["status"]}")
      Mix.shell().info("  expected: #{report["expected_sha"]}")
      Mix.shell().info("  self-test: #{report["self_test_sha"]}")
      Mix.shell().info("  actual:   #{report["actual_sha"]}")
      Mix.shell().info("  source:   #{report["source_sha"]}")
      Mix.shell().info("  drift:    #{length(report["drift"])}")

      Enum.each(report["policy_failures"], fn failure ->
        Mix.shell().error("  failure: #{failure}")
      end)
    end

    if report["status"] != "pass", do: exit({:shutdown, 1})
  end
end
