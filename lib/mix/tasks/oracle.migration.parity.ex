defmodule Mix.Tasks.Oracle.Migration.Parity do
  use Mix.Task

  alias RmxOSOracle.Migration.{
    Phase08D14LaunchctlPlist,
    Phase08MarkerManifest,
    Phase08SourceTransform
  }

  @shortdoc "Run migration parity checks for approved slices"

  @impl Mix.Task
  def run(args) do
    {opts, rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          legacy_repo: :string,
          legacy_ref: :string,
          oracle_repo: :string,
          out_root: :string,
          env_path: :string,
          lane: :string
        ]
      )

    case rest do
      ["phase08.source_transform"] ->
        run_slice("phase08.source_transform", Phase08SourceTransform, opts)

      ["phase08.marker_manifest"] ->
        run_slice("phase08.marker_manifest", Phase08MarkerManifest, opts)

      ["phase08.d14.launchctl_plist_inert_load"] ->
        run_slice("phase08.d14.launchctl_plist_inert_load", Phase08D14LaunchctlPlist, opts)

      [] ->
        Mix.shell().error(
          "missing slice id; expected phase08.source_transform, phase08.marker_manifest, or phase08.d14.launchctl_plist_inert_load"
        )

        exit({:shutdown, 1})

      [slice | _] ->
        Mix.shell().error("unsupported migration parity slice: #{slice}")
        exit({:shutdown, 1})
    end
  end

  defp run_slice(slice_id, module, opts) do
    report =
      module.run(
        legacy_repo: Keyword.get(opts, :legacy_repo, "/Users/me/wip-mach/wip-gpt"),
        legacy_ref: Keyword.get(opts, :legacy_ref, "oracle-parity-a30ef3f"),
        oracle_repo: Keyword.get(opts, :oracle_repo, File.cwd!()),
        out_root:
          Keyword.get(opts, :out_root, Path.join(File.cwd!(), "priv/runs/migration-parity")),
        env_path: Keyword.get(opts, :env_path, "priv/env/env.local"),
        lane: Keyword.get(opts, :lane, "launchd")
      )

    Mix.shell().info("oracle.migration.parity #{slice_id}: #{report["status"]}")
    Mix.shell().info("  evidence_dir: #{report["evidence_dir"]}")
    Mix.shell().info("  legacy_commit: #{report["legacy_commit"]}")
    Mix.shell().info("  oracle_commit: #{report["oracle_commit"]}")
    Mix.shell().info("  behavior_passed: #{report["behavior_passed"]}")
    Mix.shell().info("  negative_api_passed: #{report["negative_api_passed"]}")
    Mix.shell().info("  negative_mix_test_passed: #{report["negative_mix_test_passed"]}")

    Enum.each(
      [
        "boot_identity_passed",
        "marker_comparison_passed",
        "hard_stop_scan_passed",
        "negative_control_passed"
      ],
      fn key ->
        if Map.has_key?(report, key) do
          Mix.shell().info("  #{key}: #{report[key]}")
        end
      end
    )

    if report["parity_passed"] do
      :ok
    else
      exit({:shutdown, 1})
    end
  end
end
