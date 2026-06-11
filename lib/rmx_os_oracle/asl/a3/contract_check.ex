defmodule RmxOSOracle.Asl.A3.ContractCheck do
  @moduledoc """
  Exact field-record validation and static ownership checks for ASL A3.

  Marker keys and value policies are consumed from `MarkerManifest`; this module
  deliberately owns no A3 marker literal list.
  """

  alias RmxOSOracle.Asl.A3.MarkerManifest

  @authority_path "lib/rmx_os_oracle/asl/a3/marker_manifest.ex"
  @series_prefix "ASL_" <> "A3_"
  @foreign_prefixes ["ASL_" <> "A1_", "ASL_" <> "A2_", "NOTIFYD_" <> "N1_", "PHASE" <> "08_"]
  @hard_stops [
    ~r/panic:/i,
    ~r/Fatal trap/i,
    ~r/KASSERT/i,
    ~r/WITNESS:|WITNESS.*lock order|lock order reversal/i,
    ~r/SIGSYS|Bad system call|UNKNOWN FreeBSD SYSCALL|nosys [0-9]+/i
  ]

  def run(repo_root \\ File.cwd!()) do
    no_copy = no_copy_check(repo_root)
    isolation = cross_series_check(repo_root)

    %{
      "passed" => no_copy["passed"] and isolation["passed"],
      "no_copy" => no_copy,
      "cross_series" => isolation
    }
  end

  def validate_serial(serial, opts \\ []) when is_binary(serial) do
    records = parse_serial(serial)
    run_guest_rc = Keyword.get(opts, :run_guest_rc)

    errors =
      record_errors(records) ++
        unknown_key_errors(records) ++
        order_errors(records) ++
        relation_errors(records, serial) ++
        terminal_errors(records, serial, run_guest_rc) ++
        contamination_errors(serial) ++
        Enum.map(hard_stop_matches(serial), &"hard stop matched #{&1}")

    %{
      "schema" => "rmxos_oracle.asl_a3.marker_validation.v1",
      "passed" => errors == [],
      "errors" => errors,
      "marker_record_count" => length(records),
      "authority_spec_count" => length(MarkerManifest.specs()),
      "ordered_marker_count" => length(MarkerManifest.required_order()),
      "hard_stop_matches" => hard_stop_matches(serial)
    }
  end

  def marker_coverage(serial) do
    records = parse_serial(serial)
    serial_keys = records |> Enum.map(& &1.key) |> MapSet.new()
    authority_keys = MarkerManifest.marker_keys() |> MapSet.new()

    %{
      "passed" => serial_keys == authority_keys,
      "serial_keys_not_in_authority" =>
        serial_keys |> MapSet.difference(authority_keys) |> MapSet.to_list() |> Enum.sort(),
      "authority_keys_not_in_serial" =>
        authority_keys |> MapSet.difference(serial_keys) |> MapSet.to_list() |> Enum.sort()
    }
  end

  def post_run_revalidation(evidence_dir \\ MarkerManifest.accepted_evidence_dir()) do
    serial = File.read!(Path.join(evidence_dir, "serial.log"))
    rc = File.read!(Path.join(evidence_dir, "run-guest.rc")) |> String.trim()

    raw_hashes =
      Path.join(evidence_dir, "raw_evidence_hashes.json") |> File.read!() |> JSON.decode!()

    validation = validate_serial(serial, run_guest_rc: rc)
    coverage = marker_coverage(serial)
    negatives = negative_controls(serial, rc)
    serial_sha = sha256(serial)
    raw_digest = raw_hashes["tree_digest"]
    raw_file_hashes = verify_raw_file_hashes(evidence_dir, raw_hashes["files"])

    passed =
      serial_sha == MarkerManifest.accepted_serial_sha256() and
        raw_digest == MarkerManifest.raw_evidence_tree_digest() and
        raw_file_hashes["passed"] and
        validation["passed"] and coverage["passed"] and negatives["passed"]

    %{
      "schema" => "rmxos_oracle.asl_a3.authority_revalidation.v1",
      "passed" => passed,
      "accepted_claim" => if(passed, do: MarkerManifest.accepted_claim(), else: "not_accepted"),
      "serial_sha256" => serial_sha,
      "raw_evidence_tree_digest" => raw_digest,
      "raw_file_hashes_passed" => raw_file_hashes["passed"],
      "raw_file_hash_mismatches" => raw_file_hashes["mismatches"],
      "marker_validation_passed" => validation["passed"],
      "marker_coverage_passed" => coverage["passed"],
      "negative_controls_passed" => negatives["passed"],
      "raw_evidence_mutated" => false
    }
  end

  def verify_raw_file_hashes(evidence_dir, recorded_hashes) when is_map(recorded_hashes) do
    mismatches =
      Enum.flat_map(recorded_hashes, fn {name, expected} ->
        path = Path.join(evidence_dir, name)

        cond do
          not File.regular?(path) ->
            [%{"path" => name, "expected" => expected, "actual" => "missing"}]

          sha256(File.read!(path)) != expected ->
            [%{"path" => name, "expected" => expected, "actual" => sha256(File.read!(path))}]

          true ->
            []
        end
      end)

    %{"passed" => mismatches == [], "mismatches" => mismatches}
  end

  def negative_controls(serial, rc \\ "1") do
    serial = normalize_serial(serial)

    controls =
      Enum.map(MarkerManifest.negative_control_contracts(), fn contract ->
        {mutated, mutated_rc} = mutate(serial, rc, contract.id)
        report = validate_serial(mutated, run_guest_rc: mutated_rc)

        %{
          "id" => Atom.to_string(contract.id),
          "class" => Atom.to_string(contract.class),
          "passed" =>
            not report["passed"] and
              Enum.any?(report["errors"], &String.contains?(&1, contract.expected)),
          "expected_error" => contract.expected,
          "errors" => report["errors"]
        }
      end)

    %{
      "passed" => Enum.all?(controls, & &1["passed"]),
      "count" => length(controls),
      "controls" => controls
    }
  end

  def no_copy_check(repo_root \\ File.cwd!()) do
    sources =
      repo_root
      |> Path.join("lib/**/*.ex")
      |> Path.wildcard()
      |> Map.new(fn path -> {Path.relative_to(path, repo_root), File.read!(path)} end)

    no_copy_check_sources(sources)
  end

  def no_copy_check_sources(sources) when is_map(sources) do
    allowed = MapSet.new([@authority_path])

    matches =
      Enum.flat_map(sources, fn {path, source} ->
        if not MapSet.member?(allowed, path) and String.contains?(source, @series_prefix),
          do: [%{"path" => path, "prefix" => @series_prefix}],
          else: []
      end)

    %{"passed" => matches == [], "allowed_paths" => MapSet.to_list(allowed), "matches" => matches}
  end

  def cross_series_check(repo_root \\ File.cwd!()) do
    authority = File.read!(Path.join(repo_root, @authority_path))
    foreign = Enum.filter(@foreign_prefixes, &String.contains?(authority, &1))

    a3_outside =
      repo_root
      |> Path.join("lib/**/*.ex")
      |> Path.wildcard()
      |> Enum.reject(&(Path.relative_to(&1, repo_root) == @authority_path))
      |> Enum.filter(&(File.read!(&1) |> String.contains?(@series_prefix)))
      |> Enum.map(&Path.relative_to(&1, repo_root))

    %{
      "passed" => foreign == [] and a3_outside == [],
      "foreign_prefixes_in_authority" => foreign,
      "a3_prefix_outside_authority" => a3_outside
    }
  end

  def parse_serial(serial) do
    serial
    |> normalize_lines()
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      if String.starts_with?(line, @series_prefix) do
        [key | field_tokens] = String.split(line, ~r/\s+/, trim: true)

        fields =
          field_tokens
          |> Enum.map(&String.split(&1, "=", parts: 2))
          |> Enum.filter(&(length(&1) == 2))
          |> Map.new(fn [key, value] -> {String.to_atom(key), value} end)

        [%{key: key, fields: fields, line: line, line_no: line_no}]
      else
        []
      end
    end)
  end

  defp record_errors(records) do
    Enum.flat_map(MarkerManifest.specs(), fn spec ->
      matches = Enum.filter(records, &matches_spec?(&1, spec))
      same_key = Enum.filter(records, &(&1.key == spec.key))

      cond do
        length(matches) > 1 ->
          ["duplicate marker #{spec.id}"]

        matches != [] ->
          []

        same_key != [] ->
          field_errors(spec, hd(same_key))

        spec.required ->
          ["missing required marker #{spec.id}"]

        true ->
          []
      end
    end)
  end

  defp unknown_key_errors(records) do
    allowed = MarkerManifest.marker_keys() |> MapSet.new()

    records
    |> Enum.reject(&MapSet.member?(allowed, &1.key))
    |> Enum.map(&"unknown A3 marker key #{&1.key}")
  end

  defp field_errors(spec, record) do
    Enum.flat_map(spec.fields, fn {field, policy} ->
      actual = record.fields[field]

      cond do
        is_nil(actual) ->
          ["missing field #{spec.id}.#{field}"]

        policy.policy == :must_equal and actual != policy.value ->
          ["wrong field #{spec.id}.#{field}: expected #{policy.value}, got #{actual}"]

        policy.policy == :must_be_positive_integer and not integer_matches?(actual, &(&1 > 0)) ->
          ["wrong field #{spec.id}.#{field}: expected positive integer, got #{actual}"]

        policy.policy == :must_be_nonnegative_integer and not integer_matches?(actual, &(&1 >= 0)) ->
          ["wrong field #{spec.id}.#{field}: expected nonnegative integer, got #{actual}"]

        policy.policy == :must_match and not Regex.match?(policy.regex, actual) ->
          ["wrong field #{spec.id}.#{field}: value #{actual} does not match policy"]

        true ->
          []
      end
    end)
  end

  defp order_errors(records) do
    {_line, errors} =
      Enum.reduce(MarkerManifest.ordered_specs(), {0, []}, fn spec, {line, errors} ->
        case Enum.find(records, &(&1.line_no > line and matches_spec?(&1, spec))) do
          nil -> {line, errors ++ ["order violation missing #{spec.id} after line #{line}"]}
          record -> {record.line_no, errors}
        end
      end)

    errors
  end

  defp relation_errors(records, serial) do
    client_pid =
      serial
      |> normalize_serial()
      |> capture_integer(~r/^launchd donor-bootstrap harness: client pid=([0-9]+)$/m)

    audit_pid = field_integer(records, :audit_identity, :pid)
    task_pid = field_integer(records, :task_name_fence, :pid)
    service_port = field_integer(records, :service_port, :port)
    lookup_port = field_integer(records, :lookup_after, :port)
    server_port = field_integer(records, :donor_entry, :server)

    []
    |> append_if(is_nil(client_pid), "missing client pid witness")
    |> append_if(not is_nil(client_pid) and audit_pid != client_pid, "audit pid mismatch")
    |> append_if(not is_nil(client_pid) and task_pid != client_pid, "task fence pid mismatch")
    |> append_if(
      not is_nil(service_port) and lookup_port != service_port,
      "lookup port identity mismatch"
    )
    |> append_if(
      not is_nil(service_port) and server_port != service_port,
      "server port identity mismatch"
    )
  end

  defp terminal_errors(records, serial, rc) do
    server_count = count_spec(records, :server_terminal)
    client_count = count_spec(records, :client_terminal)

    harness_count =
      serial
      |> normalize_lines()
      |> Enum.count(&(&1 == MarkerManifest.terminal_contract().harness_end_marker))

    hard_stops_clean = hard_stop_matches(serial) == []
    exact_order = order_errors(records) == []

    normalized =
      rc != "1" or
        (server_count == 1 and client_count == 1 and harness_count == 1 and hard_stops_clean and
           exact_order)

    []
    |> append_if(server_count > 1, "duplicate marker server_terminal")
    |> append_if(client_count > 1, "duplicate marker client_terminal")
    |> append_if(harness_count == 0, "missing harness end rc=0")
    |> append_if(harness_count > 1, "duplicate harness end rc=0")
    |> append_if(rc == "1" and not normalized, "rc normalization failed")
    |> append_if(is_binary(rc) and rc not in ["0", "1"], "run-guest.rc=#{rc} not normalizable")
  end

  defp contamination_errors(serial) do
    Enum.flat_map(@foreign_prefixes, fn prefix ->
      if String.contains?(serial, prefix), do: ["cross-series marker #{prefix}"], else: []
    end)
  end

  defp hard_stop_matches(serial) do
    for line <- normalize_lines(serial),
        pattern <- @hard_stops,
        Regex.match?(pattern, line),
        do: line
  end

  defp matches_spec?(record, spec) do
    record.key == spec.key and field_errors(spec, record) == []
  end

  defp count_spec(records, id),
    do: Enum.count(records, &matches_spec?(&1, MarkerManifest.spec!(id)))

  defp field_integer(records, id, field) do
    case Enum.find(records, &matches_spec?(&1, MarkerManifest.spec!(id))) do
      nil -> nil
      record -> parse_integer(record.fields[field])
    end
  end

  defp capture_integer(serial, regex) do
    case Regex.run(regex, serial, capture: :all_but_first) do
      [value] -> parse_integer(value)
      _ -> nil
    end
  end

  defp integer_matches?(value, predicate) do
    case Integer.parse(value) do
      {number, ""} -> predicate.(number)
      _ -> false
    end
  end

  defp parse_integer(nil), do: nil

  defp parse_integer(value) do
    case Integer.parse(value) do
      {number, ""} -> number
      _ -> nil
    end
  end

  defp normalize_lines(serial),
    do: serial |> String.split("\n") |> Enum.map(&String.trim_trailing(&1, "\r"))

  defp sha256(data), do: :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  defp append_if(errors, true, error), do: errors ++ [error]
  defp append_if(errors, false, _error), do: errors

  defp mutate(serial, rc, :missing_terminal), do: {remove_spec(serial, :server_terminal), rc}

  defp mutate(serial, rc, :wrong_terminal),
    do: {replace_spec(serial, :server_terminal, "status=0", "status=10"), rc}

  defp mutate(serial, rc, :duplicate_terminal), do: {duplicate_spec(serial, :server_terminal), rc}
  defp mutate(serial, rc, :missing_decode), do: {remove_spec(serial, :donor_decode), rc}
  defp mutate(serial, rc, :missing_mig), do: {remove_spec(serial, :mig_server_before), rc}

  defp mutate(serial, rc, :audit_pid_mismatch),
    do: {replace_spec(serial, :audit_identity, "pid=1085", "pid=1086"), rc}

  defp mutate(serial, rc, :verify_nonzero),
    do: {replace_spec(serial, :verify_ok, "status=0", "status=10"), rc}

  defp mutate(serial, rc, :sink_before_verify),
    do: {move_before(serial, :fenced_sink, :verify_ok), rc}

  defp mutate(serial, rc, :sink_before_action_queue),
    do: {move_before(serial, :fenced_sink, :action_queue_entry), rc}

  defp mutate(serial, rc, :missing_nonce), do: {remove_spec(serial, :fenced_sink), rc}

  defp mutate(serial, rc, :wrong_nonce),
    do: {replace_spec(serial, :fenced_sink, MarkerManifest.nonce(), "wrong-nonce"), rc}

  defp mutate(serial, rc, :unfenced_store),
    do: {replace_spec(serial, :fenced_sink, "status=0", "status=1"), rc}

  defp mutate(serial, _rc, :rc_one_without_terminal),
    do: {remove_spec(serial, :server_terminal), "1"}

  defp mutate(serial, _rc, :rc_one_without_harness_end),
    do: {String.replace(serial, MarkerManifest.terminal_contract().harness_end_marker, ""), "1"}

  defp mutate(serial, rc, :truncated_serial) do
    terminal_line = line_for_spec(serial, :server_terminal)
    {serial |> String.split(terminal_line, parts: 2) |> hd(), rc}
  end

  defp mutate(serial, rc, :cross_series_contamination) do
    {serial <> "\n" <> "ASL_" <> "A1_DONE=1\n", rc}
  end

  defp remove_spec(serial, id) do
    line = line_for_spec(serial, id)
    String.replace(serial, line <> "\n", "", global: false)
  end

  defp duplicate_spec(serial, id) do
    line = line_for_spec(serial, id)
    String.replace(serial, line, line <> "\n" <> line, global: false)
  end

  defp replace_spec(serial, id, old, new) do
    line = line_for_spec(serial, id)
    String.replace(serial, line, String.replace(line, old, new), global: false)
  end

  defp move_before(serial, move_id, before_id) do
    move_line = line_for_spec(serial, move_id)
    before_line = line_for_spec(serial, before_id)

    serial
    |> String.replace(move_line <> "\n", "", global: false)
    |> String.replace(before_line, move_line <> "\n" <> before_line, global: false)
  end

  defp line_for_spec(serial, id) do
    spec = MarkerManifest.spec!(id)
    parse_serial(serial) |> Enum.find(&matches_spec?(&1, spec)) |> Map.fetch!(:line)
  end

  defp normalize_serial(serial), do: String.replace(serial, "\r\n", "\n")
end
