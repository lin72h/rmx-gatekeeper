defmodule RmxOSOracle.Asl.A3.HostScaffoldContract do
  @moduledoc """
  Oracle-owned host-scaffold contract for future ASL A3 source pins.

  This module is not ASL A3 marker authority. It validates source-owned
  host-preflight output before Oracle should consider a later A3 guest
  authorization. The contract encodes donor-source review findings about the
  default store branch, asynchronous process/action queues, and notifyd staging
  mode.
  """

  @source_design "docs/asl-a3-submit-path-design.md"
  @source_authorization "docs/asl-a3-implementation-authorization.md"
  @oracle_review "docs/asl-a3-host-scaffold-review.md"

  @required_zero_statuses [
    "asl_a3_host_preflight_status",
    "asl_a3_asl_disable_absent_status",
    "asl_a3_client_env_status",
    "asl_a3_store_fence_status",
    "asl_a3_store_fence_marker_string_status",
    "asl_a3_store_fence_falsifier_status",
    "asl_a3_acceptance_point_status",
    "asl_a3_sink_placement_status",
    "asl_a3_notifyd_staging_decision_status",
    "asl_a3_tnfp_register_session_fence_status",
    "asl_a3_action_queue_init_status",
    "asl_a3_action_queue_no_asl_conf_parse_status",
    "asl_a3_osatomic_link_status",
    "asl_a3_no_pull_in_status",
    "asl_a3_stale_a1_a2_n1_guard_status",
    "asl_a3_marker_string_status"
  ]

  @required_decisions %{
    "asl_a3_store_fence_mode" => ["fenced_send_to_asl_store"],
    "asl_a3_acceptance_point" => ["work_queue_verify_plus_selected_sink"],
    "asl_a3_sink_placement" => ["fenced_send_to_asl_store", "post_verify_work_queue"],
    "asl_a3_notifyd_staging_mode" => ["staged_notifyd_n1", "not_staged"],
    "asl_a3_task_name_for_pid_policy" => ["fenced_deferred"],
    "asl_a3_register_session_policy" => ["fenced_deferred"],
    "asl_a3_action_queue_init" => ["queue_create_only"],
    "asl_a3_asl_conf_parse" => ["disabled"],
    "asl_a3_storage_claim" => ["fenced_not_claimed"],
    "asl_a3_guest_authorized" => ["false"]
  }

  @conditional_zero_statuses %{
    {"asl_a3_notifyd_staging_mode", "staged_notifyd_n1"} => [
      "asl_a3_notifyd_n1_staging_proof_status"
    ]
  }

  @excluded_symbol_families [
    "asl_store",
    "asl_memory",
    "asl_server_query",
    "asl_server_fetch",
    "asl_server_prune",
    "asl_server_create_aux_link",
    "asl_server_register_direct_watch",
    "udp_input",
    "bsd_socket_input",
    "klog_input",
    "remote_input",
    "aslmanager"
  ]

  @required_no_pull_in_policies ["absent", "fenced", "linked_unreached"]

  def source_design, do: @source_design
  def source_authorization, do: @source_authorization
  def oracle_review, do: @oracle_review
  def required_zero_statuses, do: @required_zero_statuses
  def required_decisions, do: @required_decisions
  def excluded_symbol_families, do: @excluded_symbol_families
  def required_no_pull_in_policies, do: @required_no_pull_in_policies

  def validate_preflight(text, opts \\ []) when is_binary(text) do
    parsed = parse_preflight(text)

    errors =
      required_status_errors(parsed) ++ decision_errors(parsed) ++ symbol_policy_errors(parsed)

    warnings = warnings(parsed, opts)

    %{
      "schema" => "rmxos_oracle.asl_a3.host_scaffold_preflight.v1",
      "passed" => errors == [],
      "errors" => errors,
      "warnings" => warnings,
      "source_pin" => Keyword.get(opts, :source_pin),
      "source_design" => @source_design,
      "source_authorization" => @source_authorization,
      "oracle_review" => @oracle_review,
      "parsed" => parsed,
      "required_zero_statuses" => @required_zero_statuses,
      "required_decisions" => @required_decisions,
      "excluded_symbol_families" => @excluded_symbol_families,
      "guest_authorized" => false,
      "marker_authority" => "separate_post_acceptance_authority"
    }
  end

  def parse_preflight(text) do
    text
    |> String.split(~r/\R/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.map(&String.split(&1, "=", parts: 2))
    |> Enum.filter(&(length(&1) == 2))
    |> Map.new(fn [key, value] -> {key, value} end)
  end

  def source_requirements do
    [
      %{
        "id" => "store_fence",
        "severity" => "blocker",
        "requirement" =>
          "source preflight must prove fenced _send_to_asl_store and a red-path falsifier"
      },
      %{
        "id" => "async_acceptance",
        "severity" => "blocker",
        "requirement" =>
          "source preflight must define acceptance as work-queue verify plus selected sink"
      },
      %{
        "id" => "notifyd_staging_decision",
        "severity" => "blocker",
        "requirement" => "source preflight must declare notifyd staging mode"
      },
      %{
        "id" => "asl_disable_guard",
        "severity" => "major",
        "requirement" =>
          "source preflight must prove ASL_DISABLE is absent from the A3 client env"
      },
      %{
        "id" => "session_tracking_fence",
        "severity" => "major",
        "requirement" =>
          "source preflight must preserve task_name_for_pid/register_session as fenced-deferred"
      },
      %{
        "id" => "action_queue_init",
        "severity" => "major",
        "requirement" =>
          "source preflight must prove narrow asl_action_queue creation without asl.conf parsing"
      }
    ]
  end

  defp required_status_errors(parsed) do
    conditional_statuses =
      @conditional_zero_statuses
      |> Enum.flat_map(fn {{decision, value}, statuses} ->
        if parsed[decision] == value, do: statuses, else: []
      end)

    (@required_zero_statuses ++ conditional_statuses)
    |> Enum.flat_map(fn key ->
      case Map.fetch(parsed, key) do
        {:ok, "0"} -> []
        {:ok, value} -> ["#{key} must be 0, got #{value}"]
        :error -> ["missing required preflight status #{key}"]
      end
    end)
  end

  defp decision_errors(parsed) do
    @required_decisions
    |> Enum.flat_map(fn {key, allowed} ->
      case Map.fetch(parsed, key) do
        {:ok, value} ->
          if value in allowed,
            do: [],
            else: ["#{key} must be one of #{Enum.join(allowed, ", ")}, got #{value}"]

        :error ->
          ["missing required preflight decision #{key}"]
      end
    end)
  end

  defp symbol_policy_errors(parsed) do
    @excluded_symbol_families
    |> Enum.flat_map(fn family ->
      key = "asl_a3_no_pull_in_#{family}_policy"

      case Map.fetch(parsed, key) do
        {:ok, value} ->
          if value in @required_no_pull_in_policies,
            do: [],
            else: [
              "#{key} must be one of #{Enum.join(@required_no_pull_in_policies, ", ")}, got #{value}"
            ]

        :error ->
          ["missing no-pull-in policy #{key}"]
      end
    end)
  end

  defp warnings(parsed, _opts) do
    []
    |> add_warning(
      parsed["asl_a3_sink_placement"] == "post_verify_work_queue",
      "fallback sink placement used; _send_to_asl_store fence remains mandatory"
    )
  end

  defp add_warning(warnings, true, warning), do: warnings ++ [warning]
  defp add_warning(warnings, false, _warning), do: warnings
end
