defmodule Mix.Tasks.Oracle.Env.Check do
  use Mix.Task

  alias RmxOSOracle.CanonicalJSON
  alias RmxOSOracle.Env

  @shortdoc "Validate oracle env and lane objdir configuration"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          lane: :string,
          env: :string,
          format: :string
        ]
      )

    lane = Keyword.get(opts, :lane)

    unless lane do
      Mix.shell().error("missing required --lane (#{Enum.join(Env.lanes(), ", ")})")
      exit({:shutdown, 1})
    end

    report =
      Env.check(lane,
        env_path: Keyword.get(opts, :env, "priv/env/env.local")
      )

    if Keyword.get(opts, :format, "text") == "json" do
      Mix.shell().info(CanonicalJSON.encode!(report))
    else
      Mix.shell().info("oracle.env.check: #{report["status"]}")
      Mix.shell().info("  lane: #{report["lane"]}")
      Mix.shell().info("  freebsd_src: #{report["freebsd_src"]}")
      Mix.shell().info("  #{report["lane_objdir_env_key"]}: #{report["kernel_objdirprefix"]}")

      Mix.shell().info(
        "  projects NXPLATFORM_KERNEL_OBJDIRPREFIX=#{report["kernel_objdirprefix"]}"
      )

      Enum.each(report["errors"], fn error ->
        Mix.shell().error("  failure: #{error}")
      end)
    end

    if report["status"] != "pass", do: exit({:shutdown, 1})
  end
end
