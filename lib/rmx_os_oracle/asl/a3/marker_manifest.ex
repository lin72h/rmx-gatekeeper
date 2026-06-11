defmodule RmxOSOracle.Asl.A3.MarkerManifest do
  @moduledoc """
  Oracle-owned ASL A3 marker authority extracted from the accepted A3 run.

  The accepted claim is `donor_asl_submit_to_process_message_sink`: donor ASL
  client submission reaches donor decode, donor `process_message` verification,
  donor action fan-out, and the fenced default-store sink. Storage, query,
  retrieval, actual guest log persistence, notifyd behavior, generic Phase 0.85
  behavior, and certification remain non-claims.

  The accepted run contains no direct launchd-produced or kernel-produced marker
  facts. Check-in responses and the audit token are therefore harness-observed
  facts. Notify registration is supporting-only and notifyd was not staged.
  """

  @accepted_claim "donor_asl_submit_to_process_message_sink"
  @accepted_evidence_dir "priv/runs/asl-a3/20260611T024450Z-submit-path"
  @accepted_serial_sha256 "1020927bc4086c1c355ceb0199756521250b4f60ff6cc68fa03966824a7f6298"
  @raw_evidence_tree_digest "1a2c88f7969f7a07c1c27c2fb9dbec95568b81310f27a57a044732435efd829d"
  @source_authorization_pin "829bb25ab5a58e9a4ee522a4c288400b8a89b541"
  @runtime_scaffold_pin "d2e10c75d5565ebed397e84c456c51e685621295"
  @source_closeout_pin "b894f5abd1731d40c23003c8f0a05392098299b5"
  @service_name "com.apple.system.logger"
  @nonce "rmxos-asl-a3-submit-nonce-20260610"

  @producers [:donor, :harness]
  @roles [
    :infrastructure,
    :indirect_handoff,
    :donor_lookup,
    :client_submit,
    :generated_mig,
    :donor_decode,
    :ool_cleanup,
    :audit_identity,
    :fenced,
    :process_message,
    :fanout,
    :sink,
    :supporting,
    :terminal
  ]

  def accepted_claim, do: @accepted_claim
  def accepted_evidence_dir, do: @accepted_evidence_dir
  def accepted_serial_sha256, do: @accepted_serial_sha256
  def raw_evidence_tree_digest, do: @raw_evidence_tree_digest
  def source_authorization_pin, do: @source_authorization_pin
  def runtime_scaffold_pin, do: @runtime_scaffold_pin
  def source_closeout_pin, do: @source_closeout_pin
  def service_name, do: @service_name
  def nonce, do: @nonce
  def producers, do: @producers
  def roles, do: @roles

  def closeout do
    %{
      accepted_claim: @accepted_claim,
      accepted_evidence_path: @accepted_evidence_dir,
      accepted_serial_sha256: @accepted_serial_sha256,
      raw_evidence_tree_digest: @raw_evidence_tree_digest,
      source_pins: %{
        source_authorization: @source_authorization_pin,
        runtime_scaffold: @runtime_scaffold_pin,
        source_closeout: @source_closeout_pin
      },
      producer_facts: %{
        present: @producers,
        absent_direct_facts: [:launchd, :kernel],
        note:
          "check-in and audit-token values are harness observations; no direct launchd- or kernel-produced marker is present"
      },
      non_claims: [
        "ASL storage/query/retrieval",
        "actual guest log persistence",
        "notifyd behavior",
        "generic Phase 0.85 authority",
        "certification"
      ],
      notify_registration: "supporting_only",
      notifyd_staged: false,
      default_store_implementation: "fenced_not_claimed",
      runtime_evidence_count: 1,
      replacement_attempt_authorized: false
    }
  end

  def specs do
    [
      spec(:ldd_begin, "ASL_A3_LDD_BEGIN", %{}, :infrastructure, :harness, :link_probe,
        required: false
      ),
      spec(:ldd_end, "ASL_A3_LDD_END", %{}, :infrastructure, :harness, :link_probe,
        required: false
      ),
      spec(
        :server_init,
        "ASL_A3_SERVER_INIT",
        %{pid: pos(), max_work_queue_size: eq("10240000")},
        :infrastructure,
        :harness,
        :server_probe,
        required: false
      ),
      spec(
        :work_queue_ready,
        "ASL_A3_WORK_QUEUE_READY",
        %{ready: eq("1")},
        :infrastructure,
        :harness,
        :queue_init,
        required: false
      ),
      spec(
        :action_queue_ready,
        "ASL_A3_ACTION_QUEUE_READY",
        %{ready: eq("1"), parse_asl_conf: eq("0")},
        :fenced,
        :harness,
        :queue_init,
        required: false
      ),
      spec(
        :checkin_begin,
        "ASL_A3_CHECKIN_BEGIN",
        %{key: eq("CheckIn")},
        :indirect_handoff,
        :harness,
        :checkin_observer
      ),
      spec(
        :checkin_reply,
        "ASL_A3_CHECKIN_REPLY_PRESENT",
        %{present: eq("1")},
        :indirect_handoff,
        :harness,
        :checkin_observer
      ),
      spec(
        :machservices_dict,
        "ASL_A3_MACHSERVICES_DICT_PRESENT",
        %{present: eq("1")},
        :indirect_handoff,
        :harness,
        :checkin_observer
      ),
      spec(
        :service_entry,
        "ASL_A3_SERVICE_ENTRY_PRESENT",
        %{service: eq(@service_name), present: eq("1")},
        :indirect_handoff,
        :harness,
        :checkin_observer
      ),
      spec(
        :service_port,
        "ASL_A3_SERVICE_PORT",
        %{service: eq(@service_name), port: pos(), usable: eq("1")},
        :indirect_handoff,
        :harness,
        :checkin_observer
      ),
      spec(
        :server_recv_begin,
        "ASL_A3_SERVER_RECV_BEGIN",
        %{port: pos()},
        :infrastructure,
        :harness,
        :server_probe,
        required: false
      ),
      spec(
        :client_start,
        "ASL_A3_CLIENT_START",
        %{ident: eq("rmxos-asl-a3"), facility: eq("org.rmxos.asl.a3")},
        :client_submit,
        :harness,
        :client_probe
      ),
      spec(
        :asl_disable_absent,
        "ASL_A3_CLIENT_ENV_ASL_DISABLE",
        %{absent: eq("1")},
        :fenced,
        :harness,
        :client_probe
      ),
      spec(
        :no_remote_unset,
        "ASL_A3_CLIENT_NO_REMOTE_UNSET",
        %{opts: eq("0")},
        :fenced,
        :harness,
        :client_probe
      ),
      spec(
        :lookup_before,
        "ASL_A3_LOOKUP_BEFORE",
        %{service: eq(@service_name), target_pid: eq("0"), flags: eq("8")},
        :donor_lookup,
        :donor,
        :asl_client
      ),
      spec(
        :lookup_after,
        "ASL_A3_LOOKUP_AFTER",
        %{service: eq(@service_name), kr: eq("0"), port: pos()},
        :donor_lookup,
        :donor,
        :asl_client
      ),
      spec(
        :notify_before,
        "ASL_A3_CLIENT_NOTIFY_REGISTER_BEFORE",
        %{name: matches(~r/^com\.apple\.system\.syslog\.[1-9][0-9]*$/)},
        :supporting,
        :harness,
        :notify_observer,
        required: false,
        load_bearing: false
      ),
      spec(
        :notify_after,
        "ASL_A3_CLIENT_NOTIFY_REGISTER_AFTER",
        %{
          name: matches(~r/^com\.apple\.system\.syslog\.[1-9][0-9]*$/),
          status: eq("1000000"),
          token: eq("-1"),
          supporting: eq("1")
        },
        :supporting,
        :harness,
        :notify_observer,
        required: false,
        load_bearing: false
      ),
      spec(
        :client_open,
        "ASL_A3_CLIENT_OPEN_STATUS",
        %{client_nonnull: eq("1")},
        :client_submit,
        :donor,
        :asl_client
      ),
      spec(
        :message_create,
        "ASL_A3_CLIENT_MSG_CREATE_STATUS",
        %{msg_nonnull: eq("1")},
        :client_submit,
        :donor,
        :asl_client
      ),
      spec(
        :submit_before,
        "ASL_A3_CLIENT_SUBMIT_BEFORE",
        %{nonce: eq(@nonce)},
        :client_submit,
        :harness,
        :client_probe
      ),
      mig(:mig_user_before, "ASL_A3_MIG_USER_SEND", "before", :harness, :generated_mig),
      mig(:mig_user_after, "ASL_A3_MIG_USER_SEND", "after", :harness, :generated_mig),
      spec(
        :submit_after,
        "ASL_A3_CLIENT_SUBMIT_AFTER",
        %{status: eq("0"), nonce: eq(@nonce)},
        :client_submit,
        :donor,
        :asl_client
      ),
      spec(
        :client_close,
        "ASL_A3_CLIENT_CLOSE_STATUS",
        %{status: eq("0")},
        :client_submit,
        :donor,
        :asl_client
      ),
      spec(
        :server_receive,
        "ASL_A3_SERVER_RECV_AFTER",
        %{kr: eq("0"), msgid: eq("118"), complex: eq("1"), size: eq("56")},
        :generated_mig,
        :harness,
        :server_probe
      ),
      mig(:mig_server_before, "ASL_A3_MIG_SERVER_RCV", "before", :harness, :generated_mig),
      spec(
        :donor_entry,
        "ASL_A3_SERVER_MESSAGE_ENTRY",
        %{server: pos(), messageCnt: eq("252")},
        :donor_decode,
        :donor,
        :server_message
      ),
      spec(
        :nul_check,
        "ASL_A3_SERVER_NUL_CHECK",
        %{status: eq("0"), messageCnt: eq("252")},
        :donor_decode,
        :donor,
        :server_message
      ),
      spec(
        :donor_decode,
        "ASL_A3_SERVER_DECODE_STATUS",
        %{status: eq("0"), msg_nonnull: eq("1")},
        :donor_decode,
        :donor,
        :server_message
      ),
      spec(
        :ool_cleanup,
        "ASL_A3_SERVER_VM_DEALLOCATE",
        %{status: eq("0"), bytes: eq("252")},
        :ool_cleanup,
        :donor,
        :server_message
      ),
      spec(
        :audit_identity,
        "ASL_A3_AUDIT_TOKEN",
        %{uid: nonneg(), gid: nonneg(), pid: pos()},
        :audit_identity,
        :harness,
        :audit_observer
      ),
      spec(
        :task_name_fence,
        "ASL_A3_TASK_NAME_FOR_PID_FENCE",
        %{pid: pos(), kr: eq("5"), registered: eq("0")},
        :fenced,
        :harness,
        :session_fence
      ),
      spec(
        :process_call,
        "ASL_A3_PROCESS_MESSAGE_CALL",
        %{source: eq("5")},
        :process_message,
        :donor,
        :server_message
      ),
      spec(
        :process_entry,
        "ASL_A3_PROCESS_MESSAGE_ENTRY",
        %{source: eq("5"), msg_nonnull: eq("1")},
        :process_message,
        :donor,
        :process_message
      ),
      mig(:mig_server_after, "ASL_A3_MIG_SERVER_RCV", "after", :harness, :generated_mig),
      spec(
        :demux_status,
        "ASL_A3_SERVER_DEMUX_STATUS",
        %{status: eq("0")},
        :generated_mig,
        :harness,
        :server_probe
      ),
      spec(
        :work_queue_entry,
        "ASL_A3_PROCESS_WORK_BLOCK_ENTRY",
        %{source: eq("5"), msg_nonnull: eq("1")},
        :process_message,
        :donor,
        :process_message
      ),
      spec(
        :verify_ok,
        "ASL_A3_PROCESS_VERIFY_STATUS",
        %{source: eq("5"), status: eq("0")},
        :process_message,
        :donor,
        :process_message
      ),
      spec(
        :fanout_entry,
        "ASL_A3_FANOUT_ENTRY",
        %{source: eq("process_message_after_verify"), msg_nonnull: eq("1")},
        :fanout,
        :donor,
        :asl_action
      ),
      spec(
        :action_queue_entry,
        "ASL_A3_ACTION_QUEUE_ENTRY",
        %{module_count: eq("0"), default_store_branch: eq("1")},
        :fanout,
        :donor,
        :asl_action
      ),
      spec(
        :fenced_sink,
        "ASL_A3_STORE_FENCE_ENTRY",
        %{status: eq("0"), nonce_match: eq("1"), message: eq(@nonce)},
        :sink,
        :harness,
        :store_fence
      ),
      spec(
        :server_terminal,
        "ASL_A3_SERVER_TERMINAL",
        %{status: eq("0"), sink_status: eq("0")},
        :terminal,
        :harness,
        :orchestration
      ),
      spec(
        :client_terminal,
        "ASL_A3_CLIENT_TERMINAL",
        %{status: eq("0")},
        :terminal,
        :harness,
        :orchestration
      )
    ]
  end

  def required_order do
    [
      :checkin_begin,
      :checkin_reply,
      :machservices_dict,
      :service_entry,
      :service_port,
      :client_start,
      :asl_disable_absent,
      :no_remote_unset,
      :lookup_before,
      :lookup_after,
      :client_open,
      :message_create,
      :submit_before,
      :mig_user_before,
      :mig_user_after,
      :submit_after,
      :client_close,
      :server_receive,
      :mig_server_before,
      :donor_entry,
      :nul_check,
      :donor_decode,
      :ool_cleanup,
      :audit_identity,
      :task_name_fence,
      :process_call,
      :process_entry,
      :mig_server_after,
      :demux_status,
      :work_queue_entry,
      :verify_ok,
      :fanout_entry,
      :action_queue_entry,
      :fenced_sink,
      :server_terminal,
      :client_terminal
    ]
  end

  def terminal_contract do
    %{
      server_terminal: :server_terminal,
      client_terminal: :client_terminal,
      harness_end_marker: "=== phase1 launchd harness end rc=0 ===",
      run_guest_rc_normalization:
        "run-guest.rc=1 is accepted only with clean hard stops, exact ordered markers, both A3 terminals, and harness end rc=0"
    }
  end

  def negative_control_contracts do
    [
      %{
        id: :missing_terminal,
        class: :terminal,
        expected: "missing required marker server_terminal"
      },
      %{id: :wrong_terminal, class: :terminal, expected: "wrong field server_terminal.status"},
      %{id: :duplicate_terminal, class: :terminal, expected: "duplicate marker server_terminal"},
      %{id: :missing_decode, class: :decode, expected: "missing required marker donor_decode"},
      %{id: :missing_mig, class: :mig, expected: "order violation missing mig_server_before"},
      %{id: :audit_pid_mismatch, class: :audit, expected: "audit pid mismatch"},
      %{id: :verify_nonzero, class: :verify, expected: "wrong field verify_ok.status"},
      %{id: :sink_before_verify, class: :order, expected: "order violation"},
      %{id: :sink_before_action_queue, class: :order, expected: "order violation"},
      %{id: :missing_nonce, class: :sink, expected: "missing required marker fenced_sink"},
      %{id: :wrong_nonce, class: :sink, expected: "wrong field fenced_sink.message"},
      %{id: :unfenced_store, class: :sink, expected: "wrong field fenced_sink.status"},
      %{id: :rc_one_without_terminal, class: :rc, expected: "rc normalization failed"},
      %{id: :rc_one_without_harness_end, class: :rc, expected: "rc normalization failed"},
      %{
        id: :truncated_serial,
        class: :truncation,
        expected: "missing required marker server_terminal"
      },
      %{id: :cross_series_contamination, class: :isolation, expected: "cross-series marker"}
    ]
  end

  def spec!(id) do
    Enum.find(specs(), &(&1.id == id)) ||
      raise ArgumentError, "unknown ASL A3 marker id: #{inspect(id)}"
  end

  def marker_keys, do: specs() |> Enum.map(& &1.key) |> Enum.uniq()
  def required_specs, do: Enum.filter(specs(), & &1.required)
  def ordered_specs, do: Enum.map(required_order(), &spec!/1)
  def producer_breakdown, do: specs() |> Enum.frequencies_by(& &1.producer) |> Map.new()
  def role_breakdown, do: specs() |> Enum.frequencies_by(& &1.role) |> Map.new()

  defp mig(id, key, phase, producer, detail) do
    spec(
      id,
      key,
      %{phase: eq(phase), kind: eq("simple"), msgid: eq("118"), name: eq("_asl_server_message")},
      :generated_mig,
      producer,
      detail
    )
  end

  defp spec(id, key, fields, role, producer, producer_detail, opts \\ []) do
    %{
      id: id,
      key: key,
      fields: fields,
      role: role,
      producer: producer,
      producer_detail: producer_detail,
      required: Keyword.get(opts, :required, true),
      load_bearing: Keyword.get(opts, :load_bearing, true)
    }
  end

  defp eq(value), do: %{policy: :must_equal, value: value}
  defp pos, do: %{policy: :must_be_positive_integer}
  defp nonneg, do: %{policy: :must_be_nonnegative_integer}
  defp matches(regex), do: %{policy: :must_match, regex: regex}
end
