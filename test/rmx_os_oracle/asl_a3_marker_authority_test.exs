defmodule RmxOSOracle.AslA3MarkerAuthorityTest do
  use ExUnit.Case, async: true

  alias RmxOSOracle.Asl.A3.{ContractCheck, MarkerManifest}

  @fixture "test/fixtures/asl/a3/submit_path.accepted.serial.log"
  @provenance "test/fixtures/asl/a3/submit_path.provenance.json"

  test "accepted fixture and provenance are pinned to the accepted evidence" do
    serial = File.read!(@fixture)
    provenance = @provenance |> File.read!() |> JSON.decode!()

    assert provenance["fixture_sha256"] == sha256(serial)
    assert provenance["accepted_serial_sha256"] == MarkerManifest.accepted_serial_sha256()

    assert provenance["fixture_transformation"] ==
             "mechanical CR removal and trailing-whitespace normalization only"

    assert provenance["raw_evidence_tree_digest"] == MarkerManifest.raw_evidence_tree_digest()
    assert provenance["accepted_claim"] == MarkerManifest.accepted_claim()
  end

  test "authority represents every accepted A3 marker and validates exact field records" do
    serial = File.read!(@fixture)
    report = ContractCheck.validate_serial(serial, run_guest_rc: "1")
    coverage = ContractCheck.marker_coverage(serial)

    assert report["passed"], inspect(report["errors"])
    assert coverage["passed"], inspect(coverage)
    assert length(MarkerManifest.specs()) == 44
    assert MarkerManifest.producers() == [:donor, :harness]
    assert Enum.all?(MarkerManifest.specs(), &(&1.producer in [:donor, :harness]))
    assert MarkerManifest.closeout().producer_facts.absent_direct_facts == [:launchd, :kernel]
  end

  test "load-bearing donor behavior is donor-owned and supporting notify markers cannot prove it" do
    for id <- [
          :lookup_before,
          :lookup_after,
          :donor_entry,
          :donor_decode,
          :ool_cleanup,
          :process_entry,
          :work_queue_entry,
          :verify_ok,
          :fanout_entry,
          :action_queue_entry
        ] do
      spec = MarkerManifest.spec!(id)
      assert spec.producer == :donor
      assert spec.load_bearing
    end

    for id <- [:notify_before, :notify_after] do
      spec = MarkerManifest.spec!(id)
      assert spec.producer == :harness
      refute spec.load_bearing
      refute spec.required
    end
  end

  test "static authority checks pass and seeded copied literal is rejected" do
    report = ContractCheck.run()
    assert report["passed"], inspect(report)

    seeded =
      ContractCheck.no_copy_check_sources(%{
        "lib/rmx_os_oracle/asl/a3/marker_manifest.ex" => "",
        "lib/example.ex" => "value = \"ASL_A3_SERVER_DECODE_STATUS\""
      })

    refute seeded["passed"]
    assert [%{"path" => "lib/example.ex"}] = seeded["matches"]
  end

  test "cross-series contamination is rejected" do
    serial = File.read!(@fixture) <> "\nASL_A2_DONE status=1\n"
    report = ContractCheck.validate_serial(serial, run_guest_rc: "1")

    refute report["passed"]
    assert Enum.any?(report["errors"], &String.contains?(&1, "cross-series marker"))
  end

  test "all authority falsifiers fail for their intended reason" do
    report = ContractCheck.negative_controls(File.read!(@fixture), "1")

    assert report["passed"], inspect(Enum.reject(report["controls"], & &1["passed"]))
    assert report["count"] == 16
  end

  test "preserved accepted evidence revalidates without changing the raw run" do
    report = ContractCheck.post_run_revalidation()

    assert report["passed"], inspect(report)
    assert report["accepted_claim"] == "donor_asl_submit_to_process_message_sink"
    assert report["serial_sha256"] == MarkerManifest.accepted_serial_sha256()
    assert report["raw_evidence_tree_digest"] == MarkerManifest.raw_evidence_tree_digest()
    assert report["raw_file_hashes_passed"]
    assert report["raw_file_hash_mismatches"] == []
    assert report["raw_evidence_mutated"] == false
  end

  test "terminal rc normalization requires exact terminals clean ordering and harness end" do
    serial = File.read!(@fixture)
    assert ContractCheck.validate_serial(serial, run_guest_rc: "1")["passed"]

    refute ContractCheck.validate_serial(
             String.replace(serial, MarkerManifest.terminal_contract().harness_end_marker, ""),
             run_guest_rc: "1"
           )["passed"]
  end

  defp sha256(data), do: :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
end
