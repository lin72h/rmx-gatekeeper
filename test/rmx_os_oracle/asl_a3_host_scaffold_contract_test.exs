defmodule RmxOSOracle.AslA3HostScaffoldContractTest do
  use ExUnit.Case, async: true

  alias RmxOSOracle.Asl.A3.HostScaffoldContract

  @valid_preflight """
  asl_a3_host_preflight_status=0
  asl_a3_asl_disable_absent_status=0
  asl_a3_client_env_status=0
  asl_a3_store_fence_status=0
  asl_a3_store_fence_marker_string_status=0
  asl_a3_store_fence_falsifier_status=0
  asl_a3_acceptance_point_status=0
  asl_a3_sink_placement_status=0
  asl_a3_notifyd_staging_decision_status=0
  asl_a3_notifyd_n1_staging_proof_status=0
  asl_a3_tnfp_register_session_fence_status=0
  asl_a3_action_queue_init_status=0
  asl_a3_action_queue_no_asl_conf_parse_status=0
  asl_a3_osatomic_link_status=0
  asl_a3_no_pull_in_status=0
  asl_a3_stale_a1_a2_n1_guard_status=0
  asl_a3_marker_string_status=0
  asl_a3_store_fence_mode=fenced_send_to_asl_store
  asl_a3_acceptance_point=work_queue_verify_plus_selected_sink
  asl_a3_sink_placement=fenced_send_to_asl_store
  asl_a3_notifyd_staging_mode=staged_notifyd_n1
  asl_a3_task_name_for_pid_policy=fenced_deferred
  asl_a3_register_session_policy=fenced_deferred
  asl_a3_action_queue_init=queue_create_only
  asl_a3_asl_conf_parse=disabled
  asl_a3_storage_claim=fenced_not_claimed
  asl_a3_guest_authorized=false
  asl_a3_no_pull_in_asl_store_policy=fenced
  asl_a3_no_pull_in_asl_memory_policy=absent
  asl_a3_no_pull_in_asl_server_query_policy=absent
  asl_a3_no_pull_in_asl_server_fetch_policy=absent
  asl_a3_no_pull_in_asl_server_prune_policy=absent
  asl_a3_no_pull_in_asl_server_create_aux_link_policy=absent
  asl_a3_no_pull_in_asl_server_register_direct_watch_policy=absent
  asl_a3_no_pull_in_udp_input_policy=absent
  asl_a3_no_pull_in_bsd_socket_input_policy=absent
  asl_a3_no_pull_in_klog_input_policy=absent
  asl_a3_no_pull_in_remote_input_policy=absent
  asl_a3_no_pull_in_aslmanager_policy=absent
  """

  test "accepts complete host-scaffold preflight output" do
    report = HostScaffoldContract.validate_preflight(@valid_preflight, source_pin: "abc123")

    assert report["passed"]
    assert report["errors"] == []
    assert report["warnings"] == []
    assert report["source_pin"] == "abc123"
    refute report["guest_authorized"]
    assert report["marker_authority"] == "separate_post_acceptance_authority"
  end

  test "requires store fence status mode and falsifier" do
    preflight =
      @valid_preflight
      |> String.replace("asl_a3_store_fence_status=0", "asl_a3_store_fence_status=1")
      |> String.replace(
        "asl_a3_store_fence_mode=fenced_send_to_asl_store",
        "asl_a3_store_fence_mode=none"
      )
      |> String.replace("asl_a3_store_fence_falsifier_status=0", "")

    report = HostScaffoldContract.validate_preflight(preflight)

    refute report["passed"]
    assert "asl_a3_store_fence_status must be 0, got 1" in report["errors"]

    assert "asl_a3_store_fence_mode must be one of fenced_send_to_asl_store, got none" in report[
             "errors"
           ]

    assert "missing required preflight status asl_a3_store_fence_falsifier_status" in report[
             "errors"
           ]
  end

  test "requires async acceptance point and explicit sink placement" do
    preflight =
      @valid_preflight
      |> String.replace(
        "asl_a3_acceptance_point=work_queue_verify_plus_selected_sink",
        "asl_a3_acceptance_point=sync_process_message_return"
      )
      |> String.replace("asl_a3_sink_placement=fenced_send_to_asl_store", "")

    report = HostScaffoldContract.validate_preflight(preflight)

    refute report["passed"]

    assert "asl_a3_acceptance_point must be one of work_queue_verify_plus_selected_sink, got sync_process_message_return" in report[
             "errors"
           ]

    assert "missing required preflight decision asl_a3_sink_placement" in report["errors"]
  end

  test "allows fallback sink placement only with warning and mandatory store fence" do
    preflight =
      String.replace(
        @valid_preflight,
        "asl_a3_sink_placement=fenced_send_to_asl_store",
        "asl_a3_sink_placement=post_verify_work_queue"
      )

    report = HostScaffoldContract.validate_preflight(preflight)

    assert report["passed"]

    assert "fallback sink placement used; _send_to_asl_store fence remains mandatory" in report[
             "warnings"
           ]
  end

  test "requires notifyd staging decision and conditional N1 proof when staged" do
    missing_decision =
      String.replace(@valid_preflight, "asl_a3_notifyd_staging_mode=staged_notifyd_n1", "")

    staged_without_proof =
      String.replace(@valid_preflight, "asl_a3_notifyd_n1_staging_proof_status=0", "")

    not_staged =
      @valid_preflight
      |> String.replace(
        "asl_a3_notifyd_staging_mode=staged_notifyd_n1",
        "asl_a3_notifyd_staging_mode=not_staged"
      )
      |> String.replace("asl_a3_notifyd_n1_staging_proof_status=0", "")

    refute HostScaffoldContract.validate_preflight(missing_decision)["passed"]
    refute HostScaffoldContract.validate_preflight(staged_without_proof)["passed"]

    report = HostScaffoldContract.validate_preflight(not_staged)
    assert report["passed"]
    assert report["warnings"] == []
  end

  test "requires ASL_DISABLE guard task/session fence and narrow action queue init" do
    preflight =
      @valid_preflight
      |> String.replace(
        "asl_a3_asl_disable_absent_status=0",
        "asl_a3_asl_disable_absent_status=1"
      )
      |> String.replace(
        "asl_a3_task_name_for_pid_policy=fenced_deferred",
        "asl_a3_task_name_for_pid_policy=enabled"
      )
      |> String.replace(
        "asl_a3_register_session_policy=fenced_deferred",
        "asl_a3_register_session_policy=enabled"
      )
      |> String.replace(
        "asl_a3_action_queue_init=queue_create_only",
        "asl_a3_action_queue_init=parse_asl_conf"
      )
      |> String.replace("asl_a3_asl_conf_parse=disabled", "asl_a3_asl_conf_parse=enabled")

    report = HostScaffoldContract.validate_preflight(preflight)

    refute report["passed"]
    assert "asl_a3_asl_disable_absent_status must be 0, got 1" in report["errors"]

    assert "asl_a3_task_name_for_pid_policy must be one of fenced_deferred, got enabled" in report[
             "errors"
           ]

    assert "asl_a3_register_session_policy must be one of fenced_deferred, got enabled" in report[
             "errors"
           ]

    assert "asl_a3_action_queue_init must be one of queue_create_only, got parse_asl_conf" in report[
             "errors"
           ]

    assert "asl_a3_asl_conf_parse must be one of disabled, got enabled" in report["errors"]
  end

  test "requires named no-pull-in policy for every excluded symbol family" do
    missing =
      String.replace(@valid_preflight, "asl_a3_no_pull_in_aslmanager_policy=absent", "")

    invalid =
      String.replace(
        @valid_preflight,
        "asl_a3_no_pull_in_asl_store_policy=fenced",
        "asl_a3_no_pull_in_asl_store_policy=unknown"
      )

    missing_report = HostScaffoldContract.validate_preflight(missing)
    invalid_report = HostScaffoldContract.validate_preflight(invalid)

    refute missing_report["passed"]
    refute invalid_report["passed"]

    assert "missing no-pull-in policy asl_a3_no_pull_in_aslmanager_policy" in missing_report[
             "errors"
           ]

    assert "asl_a3_no_pull_in_asl_store_policy must be one of absent, fenced, linked_unreached, got unknown" in invalid_report[
             "errors"
           ]
  end

  test "documents source requirements and review paths" do
    requirements = HostScaffoldContract.source_requirements()

    assert Enum.any?(requirements, &(&1["id"] == "store_fence" and &1["severity"] == "blocker"))

    assert Enum.any?(
             requirements,
             &(&1["id"] == "async_acceptance" and &1["severity"] == "blocker")
           )

    assert Enum.any?(
             requirements,
             &(&1["id"] == "notifyd_staging_decision" and &1["severity"] == "blocker")
           )

    assert HostScaffoldContract.source_design() == "docs/asl-a3-submit-path-design.md"
    assert HostScaffoldContract.oracle_review() == "docs/asl-a3-host-scaffold-review.md"
  end
end
