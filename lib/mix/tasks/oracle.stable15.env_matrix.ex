defmodule Mix.Tasks.Oracle.Stable15.EnvMatrix do
  use Mix.Task

  alias RmxOSOracle.CanonicalJSON
  alias RmxOSOracle.Stable15.EnvMatrix

  @shortdoc "Run the post-activation stable/15 env-check matrix"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          format: :string
        ]
      )

    report = EnvMatrix.run()

    if Keyword.get(opts, :format, "text") == "json" do
      Mix.shell().info(CanonicalJSON.encode!(report))
    else
      Mix.shell().info("oracle.stable15.env_matrix: #{report["status"]}")
      Mix.shell().info("  cases: #{report["case_count"]}")
      Mix.shell().info("  guest_run_performed: #{report["guest_run_performed"]}")
      Mix.shell().info("  certification_claim: #{report["certification_claim"]}")

      Enum.each(report["cases"], fn case_report ->
        status = if case_report["passed"], do: "ok", else: "failed"

        Mix.shell().info(
          "  #{status}: #{case_report["id"]} expected=#{case_report["expected_status"]} actual=#{case_report["actual_status"]}"
        )

        Enum.each(case_report["errors"], fn error ->
          Mix.shell().error("    failure: #{error}")
        end)
      end)
    end

    if report["status"] != "pass", do: exit({:shutdown, 1})
  end
end
