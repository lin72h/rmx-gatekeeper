defmodule RmxOSOracle.Evidence do
  @moduledoc """
  Evidence ladder schema scaffold.

  These fields describe future claims and run artifacts. M1 creates no accepted
  certification claims.
  """

  @layers %{
    "L0" => "compile_time_abi_layout",
    "L1" => "host_semantic_probe",
    "L2" => "guest_integration_probe",
    "L3" => "macos_semantic_oracle",
    "L4" => "fuzz_property_soak"
  }

  @claim_fields ~w(
    claim_id
    minimum_satisfying_layer
    positive_markers
    negative_control
    golden_baseline_artifact
    approved_diff_policy
    hard_stop_denylist_version
    provenance
    donor_c_evidence_status
  )

  @provenance_fields ~w(
    rx_base_commit
    harness_hash
    ledger_hash
    env_values
    guest_image_hash
    probe_hash
    compiler_identity
    source_commit
  )

  def layers, do: @layers
  def claim_fields, do: @claim_fields
  def provenance_fields, do: @provenance_fields
end
