defmodule RmxOSOracle.Manifest do
  @moduledoc """
  M0 legacy source manifest handling.

  The manifest is provenance for the frozen legacy test workspace. It is not a
  command to import every listed file into the canonical oracle tree.
  """

  alias RmxOSOracle.CanonicalJSON

  @schema "rmxos_oracle.legacy_source_test_manifest.v1"
  @default_source "/Users/me/wip-mach/wip-gpt"
  @default_manifest "priv/manifests/m0_legacy_source_test_manifest.json"
  @expected_digest "e59e4a08bf2be837d38f5e5758a6f1d764dd2d278b43f09d74398fb42828d298"
  @blocking_actions ~w(keep_fixture keep_elixir keep_donor_payload_reference)
  @copy_roots ~w(mix.exs test scripts fixtures)

  def schema, do: @schema
  def default_source, do: @default_source
  def default_manifest_path, do: @default_manifest
  def expected_digest, do: @expected_digest

  def load_expected(path \\ @default_manifest) do
    CanonicalJSON.decode!(path)
  end

  def with_digest(manifest) do
    Map.put(manifest, "manifest_sha256", digest(manifest))
  end

  def digest(manifest) do
    manifest
    |> Map.delete("manifest_sha256")
    |> normalize_files()
    |> CanonicalJSON.sha256()
  end

  def check(source, manifest_path, expected_sha, mode) do
    expected = load_expected(manifest_path)
    actual = build_from_source(source, expected)
    drift = diff(expected, actual)
    policy_failures = policy_failures(drift)
    ignored_paths = ignored_manifest_paths(source, expected)
    import_status = import_relevant_status(source)
    self_test_sha = digest(expected)
    actual_sha = digest(actual)
    source_sha = git_short_sha(source)

    failures =
      []
      |> maybe_fail(self_test_sha != expected_sha, "manifest JSON self-test digest mismatch")
      |> maybe_fail(actual_sha != expected_sha, "source manifest digest mismatch")
      |> maybe_fail(
        mode == "committed" and source_sha != expected["source_sha"],
        "source SHA mismatch"
      )
      |> maybe_fail(
        mode == "committed" and import_status != [],
        "import-relevant source paths are dirty"
      )
      |> maybe_fail(ignored_paths != [], "manifest-referenced paths are gitignored")
      |> Kernel.++(policy_failures)

    %{
      "schema" => "rmxos_oracle.manifest_check.v1",
      "status" => if(failures == [], do: "pass", else: "fail"),
      "source" => Path.expand(source),
      "mode" => mode,
      "expected_sha" => expected_sha,
      "self_test_sha" => self_test_sha,
      "actual_sha" => actual_sha,
      "source_sha" => source_sha,
      "manifest_path" => manifest_path,
      "drift" => drift,
      "policy_failures" => failures,
      "ignored_paths" => ignored_paths,
      "import_relevant_status" => import_status
    }
  end

  def build_from_source(source, expected_manifest) do
    metadata_by_path =
      expected_manifest
      |> Map.fetch!("files")
      |> Map.new(fn entry -> {entry["path"], entry} end)

    files =
      source
      |> scan_paths()
      |> Enum.map(fn path -> file_entry(source, path, Map.get(metadata_by_path, path)) end)

    %{
      "schema" => @schema,
      "source_root" => Path.expand(source),
      "source_sha" => git_short_sha(source),
      "files" => files
    }
  end

  def scan_paths(source) do
    roots =
      Enum.flat_map(@copy_roots, fn
        "mix.exs" ->
          path = Path.join(source, "mix.exs")
          if File.regular?(path), do: ["mix.exs"], else: []

        root ->
          source
          |> Path.join(root)
          |> Path.join("**/*")
          |> Path.wildcard(match_dot: true)
          |> Enum.filter(&File.regular?/1)
          |> Enum.map(&Path.relative_to(&1, source))
      end)

    roots
    |> Enum.reject(&excluded?/1)
    |> Enum.sort()
  end

  def import_relevant_status(source) do
    {out, _status} =
      System.cmd(
        "git",
        ["-C", source, "status", "--short", "--untracked-files=all", "--" | @copy_roots],
        stderr_to_stdout: true
      )

    out
    |> String.split("\n", trim: true)
    |> Enum.sort()
  end

  def ignored_manifest_paths(source, manifest) do
    paths = Enum.map(manifest["files"], & &1["path"])

    case System.cmd("git", ["-C", source, "check-ignore", "--no-index", "--" | paths],
           stderr_to_stdout: true
         ) do
      {out, 0} -> String.split(out, "\n", trim: true)
      {_out, _status} -> []
    end
  end

  def git_short_sha(path) do
    case System.cmd("git", ["-C", path, "rev-parse", "--short", "HEAD"], stderr_to_stdout: true) do
      {out, 0} -> String.trim(out)
      {_out, _status} -> nil
    end
  end

  defp file_entry(source, path, nil) do
    source
    |> stat_entry(path)
    |> Map.merge(%{
      "language" => infer_language(path),
      "role" => "unknown",
      "target_action" => "unknown",
      "canonical" => false,
      "dirty_classification" => "unknown",
      "complexity" => "medium",
      "contains_embedded_awk" => contains_embedded_awk?(Path.join(source, path))
    })
  end

  defp file_entry(source, path, expected) do
    source
    |> stat_entry(path)
    |> Map.merge(Map.take(expected, metadata_fields()))
  end

  defp stat_entry(source, path) do
    absolute = Path.join(source, path)
    bytes = File.read!(absolute)

    %{
      "path" => path,
      "size" => byte_size(bytes),
      "sha256" => bytes |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower),
      "lines" => count_lines(bytes)
    }
  end

  defp count_lines(bytes), do: bytes |> :binary.matches("\n") |> length()

  defp diff(expected, actual) do
    expected_by_path = Map.new(expected["files"], fn entry -> {entry["path"], entry} end)
    actual_by_path = Map.new(actual["files"], fn entry -> {entry["path"], entry} end)

    paths =
      expected_by_path
      |> Map.keys()
      |> Kernel.++(Map.keys(actual_by_path))
      |> Enum.uniq()
      |> Enum.sort()

    Enum.flat_map(paths, fn path ->
      expected_entry = expected_by_path[path]
      actual_entry = actual_by_path[path]

      cond do
        expected_entry == nil ->
          [%{"path" => path, "kind" => "added", "target_action" => actual_entry["target_action"]}]

        actual_entry == nil ->
          [
            %{
              "path" => path,
              "kind" => "removed",
              "target_action" => expected_entry["target_action"]
            }
          ]

        content_fields(expected_entry) != content_fields(actual_entry) ->
          [
            %{
              "path" => path,
              "kind" => "modified",
              "target_action" => expected_entry["target_action"],
              "expected" => content_fields(expected_entry),
              "actual" => content_fields(actual_entry)
            }
          ]

        true ->
          []
      end
    end)
  end

  defp policy_failures(drift) do
    Enum.flat_map(drift, fn entry ->
      action = entry["target_action"]

      cond do
        entry["kind"] == "added" and action in [nil, "unknown"] ->
          ["added file has no M0 classification: #{entry["path"]}"]

        entry["kind"] in ["removed", "modified"] and action in @blocking_actions ->
          ["#{entry["kind"]} #{action} path blocks M1: #{entry["path"]}"]

        true ->
          []
      end
    end)
  end

  defp maybe_fail(failures, true, message), do: failures ++ [message]
  defp maybe_fail(failures, false, _message), do: failures

  defp normalize_files(manifest) do
    Map.update!(manifest, "files", &Enum.sort_by(&1, fn entry -> entry["path"] end))
  end

  defp content_fields(entry), do: Map.take(entry, ~w(size sha256 lines))

  defp metadata_fields do
    ~w(language role target_action canonical dirty_classification complexity contains_embedded_awk)
  end

  defp excluded?(path) do
    String.contains?(path, "/__pycache__/") or String.starts_with?(path, "__pycache__/") or
      String.ends_with?(path, ".pyc") or String.ends_with?(path, ".core")
  end

  defp infer_language(path) do
    cond do
      String.ends_with?(path, ".ex") or String.ends_with?(path, ".exs") -> "elixir"
      String.ends_with?(path, ".zig") -> "zig"
      String.ends_with?(path, ".sh") -> "shell"
      String.ends_with?(path, ".py") -> "python"
      String.ends_with?(path, ".awk") -> "awk"
      String.ends_with?(path, ".c") or String.ends_with?(path, ".h") -> "c"
      String.starts_with?(path, "fixtures/") -> "fixture"
      true -> "other"
    end
  end

  defp contains_embedded_awk?(path) do
    File.regular?(path) and String.contains?(File.read!(path), "awk")
  end
end
