defmodule RmxOSOracle.Dependency do
  @moduledoc """
  Dependency-edge derivation for imported M1 Elixir assets.
  """

  alias RmxOSOracle.CanonicalJSON
  alias RmxOSOracle.Manifest

  @schema "rmxos_oracle.dependency_edges.v1"
  @default_path "priv/dependencies/m0_dependency_edges.json"
  @scan_files [
    "lib/phase08/source_transform.ex",
    "lib/phase08/marker_manifest.ex",
    "test/phase08/source_transform_test.exs",
    "test/test_helper.exs"
  ]

  def default_path, do: @default_path

  def derive(opts \\ []) do
    files = Keyword.get(opts, :files, @scan_files)

    edges =
      files
      |> Enum.filter(&File.regular?/1)
      |> Enum.flat_map(&scan_file/1)

    %{
      "schema" => @schema,
      "generated_by" => "mix oracle.dependency.derive",
      "derived_from_manifest_sha256" => Manifest.expected_digest(),
      "scanned_files" => files,
      "edges" => edges
    }
  end

  def write!(path \\ @default_path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    CanonicalJSON.write!(path, derive())
  end

  def audit(path \\ @default_path) do
    data = CanonicalJSON.decode!(path)
    errors = shape_errors(data) ++ canonical_blockers(data)

    %{
      "schema" => "rmxos_oracle.dependency_audit.v1",
      "status" => if(errors == [], do: "pass", else: "fail"),
      "path" => path,
      "edge_count" => length(data["edges"] || []),
      "errors" => errors
    }
  end

  defp scan_file(path) do
    text = File.read!(path)

    []
    |> Kernel.++(regex_edges(path, text, ~r/Code\.require_file\(([^)]+)\)/, "require_file"))
    |> Kernel.++(regex_edges(path, text, ~r/System\.cmd\(([^)]+)\)/, "exec"))
    |> Kernel.++(regex_edges(path, text, ~r/Port\.open\(([^)]+)\)/, "exec"))
    |> Kernel.++(regex_edges(path, text, ~r/["']([^"']+\.(?:sh|py))["']/, "exec"))
    |> Kernel.++(regex_edges(path, text, ~r/["']([^"']+\.(?:plist|json))["']/, "fixture"))
    |> Kernel.++(regex_edges(path, text, ~r/["']([^"']+\.(?:c|h|zig))["']/, "payload"))
    |> Enum.uniq()
  end

  defp regex_edges(path, text, regex, edge_type) do
    Regex.scan(regex, text)
    |> Enum.map(fn [_match, dependency] ->
      dependency = String.trim(dependency)

      %{
        "consumer" => path,
        "dependency" => dependency,
        "dependency_language" => infer_language(dependency),
        "dependency_action" => dependency_action(dependency),
        "edge_type" => edge_type,
        "canonical_status" => canonical_status(edge_type, dependency)
      }
    end)
  end

  defp shape_errors(data) do
    []
    |> maybe_error(data["schema"] != @schema, "unexpected dependency schema")
    |> maybe_error(not is_list(data["edges"]), "edges must be a list")
  end

  defp canonical_blockers(data) do
    data
    |> Map.get("edges", [])
    |> Enum.flat_map(fn edge ->
      if edge["canonical_status"] == "blocked" do
        ["blocked dependency edge: #{edge["consumer"]} -> #{edge["dependency"]}"]
      else
        []
      end
    end)
  end

  defp maybe_error(errors, true, message), do: errors ++ [message]
  defp maybe_error(errors, false, _message), do: errors

  defp infer_language(path) do
    cond do
      String.ends_with?(path, ".ex") or String.ends_with?(path, ".exs") -> "elixir"
      String.ends_with?(path, ".sh") -> "shell"
      String.ends_with?(path, ".py") -> "python"
      String.ends_with?(path, ".c") or String.ends_with?(path, ".h") -> "c"
      String.ends_with?(path, ".zig") -> "zig"
      String.ends_with?(path, ".plist") or String.ends_with?(path, ".json") -> "fixture"
      true -> "unknown"
    end
  end

  defp dependency_action(path) do
    case infer_language(path) do
      "shell" -> "port_to_elixir"
      "python" -> "port_to_elixir"
      "c" -> "retain_c_reference_until_zig_parity"
      _ -> "keep_elixir_or_fixture"
    end
  end

  defp canonical_status(edge_type, dependency) do
    cond do
      edge_type == "require_file" -> "blocked"
      infer_language(dependency) in ["shell", "python"] -> "blocked"
      infer_language(dependency) == "c" -> "reference_only"
      true -> "canonical"
    end
  end
end
