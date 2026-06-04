defmodule Phase08.MarkerManifest do
  @moduledoc false

  @d22_running_label "org.rmxos.phase08.d22.running-remove"
  @d22_keepalive_label "org.rmxos.phase08.d22.keepalive-remove"
  @d23_inert_label "org.rmxos.phase08.d23.inert-reload"
  @d23_keepalive_label "org.rmxos.phase08.d23.keepalive-reload"

  @markers [
    %{
      id: :d22_running_live_job_label,
      key: "PHASE08_D22_RUNNING_REMOVE_LIVE_JOB_LABEL",
      gate: :d22,
      arm: :running,
      type: :string,
      policy: {:must_equal, @d22_running_label},
      producer: :donor,
      claim: "Remove handler observed the live donor j->label for the running non-KeepAlive arm."
    },
    %{
      id: :d22_running_live_job_label_match,
      key: "PHASE08_D22_RUNNING_REMOVE_LIVE_JOB_LABEL_MATCH",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "Live donor j->label matched the expected running non-KeepAlive fixture label."
    },
    %{
      id: :d22_running_keepalive_true_before_remove,
      key: "PHASE08_D22_RUNNING_KEEPALIVE_CONFIG_TRUE_BEFORE_REMOVE",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "KeepAlive was false before removing the running non-KeepAlive arm."
    },
    %{
      id: :d22_running_keepalive_configured,
      key: "PHASE08_D22_RUNNING_KEEPALIVE_CONFIGURED",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "The running non-KeepAlive arm had no KeepAlive key configured."
    },
    %{
      id: :d22_running_removal_pending_before_signal,
      key: "PHASE08_D22_RUNNING_REMOVAL_PENDING_SET_BEFORE_SIGNAL",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "removal_pending was set before donor termination in the running non-KeepAlive arm."
    },
    %{
      id: :d22_running_donor_sent_signal,
      key: "PHASE08_D22_RUNNING_DONOR_SENT_SIGNAL",
      gate: :d22,
      arm: :running,
      type: :enum,
      policy: {:must_be_one_of, ["SIGTERM", "SIGKILL"]},
      producer: :donor,
      claim: "job_stop terminated the running non-KeepAlive arm through the donor signal path."
    },
    %{
      id: :d22_running_job_useless_reason,
      key: "PHASE08_D22_RUNNING_JOB_USELESS_REASON",
      gate: :d22,
      arm: :running,
      type: :enum,
      policy: {:must_equal, "removal_pending"},
      producer: :donor,
      claim: "job_useless short-circuited post-reap dispatch because removal was pending."
    },
    %{
      id: :d22_running_keepalive_not_reached,
      key: "PHASE08_D22_RUNNING_KEEPALIVE_REACHED_POST_REAP",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "Post-reap teardown preempted job_keepalive in the running non-KeepAlive arm."
    },
    %{
      id: :d22_running_no_restart_after_remove,
      key: "PHASE08_D22_RUNNING_KEEPALIVE_RESTART_AFTER_REMOVE",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "No replacement process started after RemoveJob for the running non-KeepAlive arm."
    },
    %{
      id: :d22_running_deferred_enter_count,
      key: "PHASE08_D22_RUNNING_REMOVE_HANDLER_ENTER_COUNT",
      gate: :d22,
      arm: :running,
      type: :count,
      policy: {:must_include, "2"},
      producer: :donor,
      claim: "job_remove re-entered for deferred cleanup after the running non-KeepAlive reap."
    },
    %{
      id: :d22_running_deferred_removal_completed,
      key: "PHASE08_D22_RUNNING_DEFERRED_REMOVAL_COMPLETED",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "Deferred table removal completed for the running non-KeepAlive arm."
    },
    %{
      id: :d22_running_job_removed_from_table,
      key: "PHASE08_D22_RUNNING_JOB_REMOVED_FROM_TABLE",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The running non-KeepAlive job was no longer present in donor job tables."
    },
    %{
      id: :d22_running_no_orphan,
      key: "PHASE08_D22_RUNNING_ORPHANED_PROCESS_CHECK",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "The original running non-KeepAlive PID did not survive as an orphan."
    },
    %{
      id: :d22_running_arm_confirmed,
      key: "PHASE08_D22_RUNNING_RUNNING_REMOVE_CONFIRMED",
      gate: :d22,
      arm: :running,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The running non-KeepAlive RemoveJob arm satisfied its terminal proof."
    },
    %{
      id: :d22_keepalive_live_job_label,
      key: "PHASE08_D22_KEEPALIVE_REMOVE_LIVE_JOB_LABEL",
      gate: :d22,
      arm: :keepalive,
      type: :string,
      policy: {:must_equal, @d22_keepalive_label},
      producer: :donor,
      claim: "Remove handler observed the live donor j->label for the running KeepAlive arm."
    },
    %{
      id: :d22_keepalive_live_job_label_match,
      key: "PHASE08_D22_KEEPALIVE_REMOVE_LIVE_JOB_LABEL_MATCH",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "Live donor j->label matched the expected KeepAlive fixture label."
    },
    %{
      id: :d22_keepalive_true_before_remove,
      key: "PHASE08_D22_KEEPALIVE_KEEPALIVE_CONFIG_TRUE_BEFORE_REMOVE",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "KeepAlive was true before removing the running KeepAlive arm."
    },
    %{
      id: :d22_keepalive_configured,
      key: "PHASE08_D22_KEEPALIVE_KEEPALIVE_CONFIGURED",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The running KeepAlive arm had KeepAlive configured."
    },
    %{
      id: :d22_keepalive_removal_pending_before_signal,
      key: "PHASE08_D22_KEEPALIVE_REMOVAL_PENDING_SET_BEFORE_SIGNAL",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "removal_pending was set before donor termination in the running KeepAlive arm."
    },
    %{
      id: :d22_keepalive_donor_sent_signal,
      key: "PHASE08_D22_KEEPALIVE_DONOR_SENT_SIGNAL",
      gate: :d22,
      arm: :keepalive,
      type: :enum,
      policy: {:must_be_one_of, ["SIGTERM", "SIGKILL"]},
      producer: :donor,
      claim: "job_stop terminated the running KeepAlive arm through the donor signal path."
    },
    %{
      id: :d22_keepalive_job_useless_reason,
      key: "PHASE08_D22_KEEPALIVE_JOB_USELESS_REASON",
      gate: :d22,
      arm: :keepalive,
      type: :enum,
      policy: {:must_equal, "removal_pending"},
      producer: :donor,
      claim: "job_useless short-circuited post-reap dispatch because removal was pending."
    },
    %{
      id: :d22_keepalive_keepalive_not_reached,
      key: "PHASE08_D22_KEEPALIVE_KEEPALIVE_REACHED_POST_REAP",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "Post-reap teardown preempted job_keepalive in the running KeepAlive arm."
    },
    %{
      id: :d22_keepalive_no_restart_after_remove,
      key: "PHASE08_D22_KEEPALIVE_KEEPALIVE_RESTART_AFTER_REMOVE",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "No replacement process started after RemoveJob for the running KeepAlive arm."
    },
    %{
      id: :d22_keepalive_deferred_enter_count,
      key: "PHASE08_D22_KEEPALIVE_REMOVE_HANDLER_ENTER_COUNT",
      gate: :d22,
      arm: :keepalive,
      type: :count,
      policy: {:must_include, "2"},
      producer: :donor,
      claim: "job_remove re-entered for deferred cleanup after the running KeepAlive reap."
    },
    %{
      id: :d22_keepalive_deferred_removal_completed,
      key: "PHASE08_D22_KEEPALIVE_DEFERRED_REMOVAL_COMPLETED",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "Deferred table removal completed for the running KeepAlive arm."
    },
    %{
      id: :d22_keepalive_job_removed_from_table,
      key: "PHASE08_D22_KEEPALIVE_JOB_REMOVED_FROM_TABLE",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The running KeepAlive job was no longer present in donor job tables."
    },
    %{
      id: :d22_keepalive_no_orphan,
      key: "PHASE08_D22_KEEPALIVE_ORPHANED_PROCESS_CHECK",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "The original running KeepAlive PID did not survive as an orphan."
    },
    %{
      id: :d22_keepalive_arm_confirmed,
      key: "PHASE08_D22_KEEPALIVE_RUNNING_REMOVE_CONFIRMED",
      gate: :d22,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The running KeepAlive RemoveJob arm satisfied its terminal proof."
    },
    %{
      id: :d22_gate_confirmed,
      key: "PHASE08_D22_RUNNING_REMOVE_CONFIRMED",
      gate: :d22,
      arm: nil,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "Both D22 running RemoveJob arms completed."
    },
    %{
      id: :d23_requested,
      key: "PHASE08_D23_RELOAD_REQUESTED",
      gate: :d23,
      arm: nil,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "D23 same-label reload gate was requested."
    },
    %{
      id: :d23_inert_expected_label,
      key: "PHASE08_D23_INERT_EXPECTED_LABEL",
      gate: :d23,
      arm: :inert,
      type: :string,
      policy: {:must_equal, @d23_inert_label},
      producer: :harness,
      claim: "The inert reload arm targets the D23 inert fixture label."
    },
    %{
      id: :d23_inert_load_delta,
      key: "PHASE08_D23_INERT_LOAD_MIG437_DELTA",
      gate: :d23,
      arm: :inert,
      type: :count,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "Initial inert load sent exactly one MIG 437 management request."
    },
    %{
      id: :d23_inert_remove_delta,
      key: "PHASE08_D23_INERT_REMOVE_MIG437_DELTA",
      gate: :d23,
      arm: :inert,
      type: :count,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "Inert remove sent exactly one MIG 437 management request."
    },
    %{
      id: :d23_inert_reload_delta,
      key: "PHASE08_D23_INERT_RELOAD_MIG437_DELTA",
      gate: :d23,
      arm: :inert,
      type: :count,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "Same-label inert reload sent exactly one MIG 437 management request."
    },
    %{
      id: :d23_inert_reload_find_null,
      key: "PHASE08_D23_INERT_RELOAD_JOB_FIND_RETURNED_NULL",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The reload EEXIST gate evaluated job_find and found no stale inert label."
    },
    %{
      id: :d23_inert_duplicate_rejected,
      key: "PHASE08_D23_INERT_RELOAD_DUPLICATE_REJECTED",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "The inert reload was not rejected as a duplicate label."
    },
    %{
      id: :d23_inert_removed_label_count,
      key: "PHASE08_D23_INERT_LABEL_COUNT_AFTER_REMOVE",
      gate: :d23,
      arm: :inert,
      type: :count,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "The inert label hash entry was gone before reload."
    },
    %{
      id: :d23_inert_remove_delta_ok,
      key: "PHASE08_D23_INERT_DONOR_JOB_TABLE_COUNT_REMOVE_DELTA_OK",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The inert remove reduced the donor job table by exactly one."
    },
    %{
      id: :d23_inert_no_leak,
      key: "PHASE08_D23_INERT_JOB_STRUCT_NO_LEAK_AFTER_REMOVE",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The old inert job struct was no longer represented in the donor label table."
    },
    %{
      id: :d23_inert_proc_source_removed,
      key: "PHASE08_D23_INERT_OLD_PROC_SOURCE_CANCELLED_OR_NONE",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The inert old job had no dangling proc source at remove completion."
    },
    %{
      id: :d23_inert_kqueue_removed,
      key: "PHASE08_D23_INERT_OLD_KQUEUE_PROC_IDENT_DEREGISTERED_OR_NONE",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The inert old job had no stale EVFILT_PROC ident at remove completion."
    },
    %{
      id: :d23_inert_timers_removed,
      key: "PHASE08_D23_INERT_OLD_TIMER_IDENTS_DEREGISTERED_OR_NONE",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The inert old job had no stale timer ident at remove completion."
    },
    %{
      id: :d23_inert_global_baseline,
      key: "PHASE08_D23_INERT_GLOBAL_ON_DEMAND_CNT_BASELINE",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The inert remove returned global on-demand accounting to baseline."
    },
    %{
      id: :d23_inert_reload_accepted,
      key: "PHASE08_D23_INERT_RELOAD_ACCEPTED",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The same-label inert reload created a valid donor job."
    },
    %{
      id: :d23_inert_arm_confirmed,
      key: "PHASE08_D23_INERT_ARM_CONFIRMED",
      gate: :d23,
      arm: :inert,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "The inert remove then same-label reload arm completed."
    },
    %{
      id: :d23_keepalive_expected_label,
      key: "PHASE08_D23_KEEPALIVE_EXPECTED_LABEL",
      gate: :d23,
      arm: :keepalive,
      type: :string,
      policy: {:must_equal, @d23_keepalive_label},
      producer: :harness,
      claim: "The running KeepAlive reload arm targets the D23 KeepAlive fixture label."
    },
    %{
      id: :d23_keepalive_load_delta,
      key: "PHASE08_D23_KEEPALIVE_LOAD_MIG437_DELTA",
      gate: :d23,
      arm: :keepalive,
      type: :count,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "Initial running KeepAlive load sent exactly one MIG 437 management request."
    },
    %{
      id: :d23_keepalive_remove_delta,
      key: "PHASE08_D23_KEEPALIVE_REMOVE_MIG437_DELTA",
      gate: :d23,
      arm: :keepalive,
      type: :count,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "Running KeepAlive remove sent exactly one MIG 437 management request."
    },
    %{
      id: :d23_keepalive_reload_delta,
      key: "PHASE08_D23_KEEPALIVE_RELOAD_MIG437_DELTA",
      gate: :d23,
      arm: :keepalive,
      type: :count,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "Same-label running KeepAlive reload sent exactly one MIG 437 management request."
    },
    %{
      id: :d23_keepalive_reload_find_null,
      key: "PHASE08_D23_KEEPALIVE_RELOAD_JOB_FIND_RETURNED_NULL",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim:
        "The reload EEXIST gate evaluated job_find and found no stale running KeepAlive label."
    },
    %{
      id: :d23_keepalive_duplicate_rejected,
      key: "PHASE08_D23_KEEPALIVE_RELOAD_DUPLICATE_REJECTED",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "The running KeepAlive reload was not rejected as a duplicate label."
    },
    %{
      id: :d23_keepalive_removed_label_count,
      key: "PHASE08_D23_KEEPALIVE_LABEL_COUNT_AFTER_REMOVE",
      gate: :d23,
      arm: :keepalive,
      type: :count,
      policy: {:must_equal, "0"},
      producer: :donor,
      claim: "The running KeepAlive label hash entry was gone before reload."
    },
    %{
      id: :d23_keepalive_remove_delta_ok,
      key: "PHASE08_D23_KEEPALIVE_DONOR_JOB_TABLE_COUNT_REMOVE_DELTA_OK",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The running KeepAlive remove reduced the donor job table by exactly one."
    },
    %{
      id: :d23_keepalive_no_leak,
      key: "PHASE08_D23_KEEPALIVE_JOB_STRUCT_NO_LEAK_AFTER_REMOVE",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim:
        "The old running KeepAlive job struct was no longer represented in the donor label table."
    },
    %{
      id: :d23_keepalive_proc_source_removed,
      key: "PHASE08_D23_KEEPALIVE_OLD_PROC_SOURCE_CANCELLED_OR_NONE",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The old running KeepAlive job had no dangling proc source at remove completion."
    },
    %{
      id: :d23_keepalive_kqueue_removed,
      key: "PHASE08_D23_KEEPALIVE_OLD_KQUEUE_PROC_IDENT_DEREGISTERED_OR_NONE",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The old running KeepAlive job had no stale EVFILT_PROC ident at remove completion."
    },
    %{
      id: :d23_keepalive_timers_removed,
      key: "PHASE08_D23_KEEPALIVE_OLD_TIMER_IDENTS_DEREGISTERED_OR_NONE",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The old running KeepAlive job had no stale timer ident at remove completion."
    },
    %{
      id: :d23_keepalive_global_baseline,
      key: "PHASE08_D23_KEEPALIVE_GLOBAL_ON_DEMAND_CNT_BASELINE",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The running KeepAlive remove returned global on-demand accounting to baseline."
    },
    %{
      id: :d23_keepalive_no_restart,
      key: "PHASE08_D23_KEEPALIVE_REPLACEMENT_PID_OBSERVED",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :harness,
      claim: "No KeepAlive replacement appeared between remove completion and reload."
    },
    %{
      id: :d23_keepalive_no_orphan,
      key: "PHASE08_D23_KEEPALIVE_ORPHANED_PROCESS_CHECK",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "0"},
      producer: :harness,
      claim: "The original running KeepAlive PID did not survive as an orphan before reload."
    },
    %{
      id: :d23_keepalive_reload_accepted,
      key: "PHASE08_D23_KEEPALIVE_RELOAD_ACCEPTED",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :donor,
      claim: "The same-label running KeepAlive reload created a valid donor job."
    },
    %{
      id: :d23_keepalive_arm_confirmed,
      key: "PHASE08_D23_KEEPALIVE_ARM_CONFIRMED",
      gate: :d23,
      arm: :keepalive,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "The running KeepAlive remove then same-label reload arm completed."
    },
    %{
      id: :d23_gate_confirmed,
      key: "PHASE08_D23_SAME_LABEL_RELOAD_CONFIRMED",
      gate: :d23,
      arm: nil,
      type: :bool_int,
      policy: {:must_equal, "1"},
      producer: :harness,
      claim: "Both D23 same-label reload arms completed."
    }
  ]

  def markers, do: @markers

  def for_gate(gate) do
    Enum.filter(@markers, &(&1.gate == gate))
  end

  def for_arm(gate, arm) do
    Enum.filter(@markers, &(&1.gate == gate and &1.arm == arm))
  end

  def key!(id) do
    spec!(id).key
  end

  def spec!(id) do
    case Enum.find(@markers, &(&1.id == id)) do
      nil -> raise ArgumentError, "unknown Phase 0.8 marker id: #{inspect(id)}"
      spec -> spec
    end
  end

  def emit_c(id, value_expr, fmt_or_opts \\ "%s", opts \\ [])

  def emit_c(id, value_expr, fmt, opts)
      when is_atom(id) and is_binary(fmt) and is_list(opts) do
    spec = spec!(id)
    value_expr = validate_value_expr!(id, value_expr)
    validate_static_value!(spec, Keyword.fetch(opts, :value))

    ~s|printf("#{c_printf_escape(spec.key)}=#{c_escape(fmt)}\\n", #{value_expr});|
  end

  def emit_c(id, value_expr, opts, []) when is_atom(id) and is_list(opts) do
    fmt = Keyword.get(opts, :fmt, "%s")
    emit_c(id, value_expr, fmt, opts)
  end

  def c_key!(id) when is_atom(id), do: c_escape(key!(id))

  def c_string_literal(value) when is_binary(value), do: ~s|"#{c_escape(value)}"|

  def validate_unique! do
    duplicate_ids =
      @markers
      |> Enum.group_by(& &1.id)
      |> Enum.filter(fn {_id, specs} -> length(specs) > 1 end)
      |> Enum.map(&elem(&1, 0))

    duplicate_keys =
      @markers
      |> Enum.group_by(& &1.key)
      |> Enum.filter(fn {_key, specs} -> length(specs) > 1 end)
      |> Enum.map(&elem(&1, 0))

    case {duplicate_ids, duplicate_keys} do
      {[], []} ->
        :ok

      _ ->
        raise ArgumentError,
              "duplicate marker manifest entries ids=#{inspect(duplicate_ids)} keys=#{inspect(duplicate_keys)}"
    end
  end

  def validate_log!(log, gate) when is_binary(log) do
    validate_unique!()

    gate
    |> for_gate()
    |> Enum.each(&validate_marker_in_log!(log, &1))

    :ok
  end

  def marker_values(log, key) do
    regex = ~r/^#{Regex.escape(key)}=([^\r\n]*)/m

    regex
    |> Regex.scan(log)
    |> Enum.map(fn [_, value] -> String.trim(value) end)
  end

  defp validate_marker_in_log!(log, spec) do
    values = marker_values(log, spec.key)

    if values == [] do
      raise ArgumentError, "missing marker #{spec.key}: #{spec.claim}"
    end

    validate_policy!(spec, values)
  end

  defp validate_policy!(%{policy: {:must_equal, expected}} = spec, values) do
    expected = to_string(expected)

    unless Enum.all?(values, &(&1 == expected)) do
      raise ArgumentError,
            "marker #{spec.key} expected all values #{inspect(expected)}, got #{inspect(values)}"
    end
  end

  defp validate_policy!(%{policy: {:must_include, expected}} = spec, values) do
    expected = to_string(expected)

    unless expected in values do
      raise ArgumentError,
            "marker #{spec.key} expected to include #{inspect(expected)}, got #{inspect(values)}"
    end
  end

  defp validate_policy!(%{policy: {:must_be_one_of, allowed}} = spec, values) do
    allowed = MapSet.new(Enum.map(allowed, &to_string/1))
    bad = Enum.reject(values, &MapSet.member?(allowed, &1))

    unless bad == [] do
      raise ArgumentError,
            "marker #{spec.key} expected values in #{inspect(MapSet.to_list(allowed))}, got bad values #{inspect(bad)}"
    end
  end

  defp validate_value_expr!(id, value_expr) when is_binary(value_expr) do
    if value_expr == "" do
      raise ArgumentError, "marker #{inspect(id)} emit_c requires a non-empty value expression"
    end

    value_expr
  end

  defp validate_value_expr!(id, value_expr) do
    raise ArgumentError,
          "marker #{inspect(id)} emit_c requires a binary value expression, got #{inspect(value_expr)}"
  end

  defp validate_static_value!(_spec, :error), do: :ok

  defp validate_static_value!(%{policy: {:must_equal, expected}} = spec, {:ok, value}) do
    unless to_string(value) == to_string(expected) do
      raise ArgumentError,
            "marker #{spec.key}: emit_c value #{inspect(value)} != manifest expected #{inspect(expected)}"
    end
  end

  defp validate_static_value!(%{policy: {:must_include, expected}} = spec, {:ok, value}) do
    unless to_string(value) == to_string(expected) do
      raise ArgumentError,
            "marker #{spec.key}: emit_c value #{inspect(value)} is not the required included value #{inspect(expected)}"
    end
  end

  defp validate_static_value!(%{policy: {:must_be_one_of, allowed}} = spec, {:ok, value}) do
    allowed = MapSet.new(Enum.map(allowed, &to_string/1))

    unless MapSet.member?(allowed, to_string(value)) do
      raise ArgumentError,
            "marker #{spec.key}: emit_c value #{inspect(value)} is not in #{inspect(MapSet.to_list(allowed))}"
    end
  end

  defp c_printf_escape(value) do
    value
    |> c_escape()
    |> String.replace("%", "%%")
  end

  defp c_escape(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
    |> String.replace("\t", "\\t")
  end
end
