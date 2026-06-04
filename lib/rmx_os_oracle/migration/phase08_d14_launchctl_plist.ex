defmodule RmxOSOracle.Migration.Phase08D14LaunchctlPlist do
  @moduledoc """
  Transitional L2 guest runner for D14 launchctl plist inert-load parity.

  This module does not execute the legacy verifier. It uses the verifier at
  `oracle-parity-a30ef3f^{commit}` as immutable contract source and validates
  one oracle-owned guest run against that contract.
  """

  alias RmxOSOracle.{CanonicalJSON, Env, Paths}

  @slice_id "phase08.d14.launchctl_plist_inert_load"
  @expected_legacy_commit "a30ef3f"
  @default_legacy_repo "/Users/me/wip-mach/wip-gpt"
  @default_legacy_ref "oracle-parity-a30ef3f"
  @default_oracle_repo "/Users/me/wip-mach/wip-gpt-oracle"
  @legacy_contract_path "scripts/launchd/verify-phase08-launchd-dispatch-launchctl-plist.exs"
  @legacy_contract_sha256 "2b5527ae750f7df7decc0f90ebe33998db452a2b7eb08a3482ba02a55731727f"
  @fixture_path "fixtures/launchd/org.rmxos.phase08.d14.noop.plist"
  @fixture_sha256 "27a0dd69ca86f3f3ea732de6ea1d55680955fb9ccf6063594b286761d44cb310"
  @kernel_conf_default "MACHDEBUGDEBUG"

  @executed_tool_paths [
    "scripts/bhyve/build-phase1-minibootstrap.sh",
    "scripts/bhyve/stage-libmach.sh",
    "scripts/launchd/build-bootstrap-donor-tests.sh",
    "scripts/launchd/build-phase08-d14-launchctl.sh",
    "scripts/dispatch/compile-libdispatch-build-lane.sh",
    "scripts/launchd/compile-launchd-objects.sh",
    "scripts/launchd/link-launchd-harness.sh",
    "scripts/bhyve/stage-phase1-launchd-harness-guest.sh",
    "scripts/bhyve/stage-guest.sh",
    "scripts/bhyve/run-guest.sh"
  ]
  @legacy_files Enum.uniq([@legacy_contract_path, @fixture_path | @executed_tool_paths])

  @oracle_files [
    "lib/mix/tasks/oracle.migration.parity.ex",
    "lib/rmx_os_oracle/migration/phase08_d14_launchctl_plist.ex"
  ]

  @required_exact_markers [
    "phase1_launchd_harness_mode=dispatch-launchctl-plist",
    "mach_module=loaded",
    "phase08_dispatch_main_start",
    "PHASE08_D7_DISPATCH_MAIN_DRIVER_QUEUE_CREATED=1",
    "PHASE08_D7_DISPATCH_MAIN_DRIVER_SCHEDULED=1",
    "PHASE08_D7_DISPATCH_MAIN_ENTER=1",
    "PHASE08_D7_DISPATCH_MAIN_DRIVER_STARTED=1",
    "phase08_dispatch_bootstrap_start",
    "phase08_dispatch_lifecycle_start",
    "phase08_dispatch_state_start",
    "phase08_dispatch_donor_state_start",
    "phase08_dispatch_caller_creds_start",
    "phase08_dispatch_exit_state_start",
    "phase08_dispatch_restart_start",
    "phase08_dispatch_main_cycle_start",
    "phase08_dispatch_runtime_start",
    "phase08_dispatch_proc_event_start",
    "phase08_dispatch_supervision_start",
    "phase08_dispatch_launchctl_request_start",
    "phase08_dispatch_submitjob_start",
    "phase08_dispatch_runatload_start",
    "phase08_dispatch_spawn_start",
    "PHASE08_REAL_DISPATCH=1",
    "PHASE08_NO_DISPATCH_STUBS=1",
    "PHASE08_NO_DISPATCH_SOURCE_TYPE_STUBS=1",
    "PHASE08_STAGED_LIBTHR=/root/twq-lib/libthr.so.3",
    "phase08_dispatch_launchctl_plist_start",
    "PHASE08_D14_CLIENT=donor_launchctl",
    "PHASE08_D14_COMMAND=load",
    "PHASE08_D14_LOAD_SUBCOMMAND=1",
    "PHASE08_D14_ASL_USED=0",
    "PHASE08_D14_EXPECTED_LABEL=org.rmxos.phase08.d14.noop",
    "PHASE08_D14_DONOR_JOB_PREEXISTING=0",
    "PHASE08_D14_UFLAG_BEFORE=1",
    "PHASE08_D14_UFLAG_FORCED_ZERO=1",
    "PHASE08_D14_UFLAG_DURING_DISPATCH=0",
    "PHASE08_D14_UFLAG_RESTORED=1",
    "PHASE08_D14_LOAD_JOB_CALLED=1",
    "PHASE08_D14_PLIST_SUFFIX_SELECTED=1",
    "PHASE08_D14_JSON_ADAPTER_USED=0",
    "PHASE08_D14_PLIST_PARSER=plist_to_launch_data_expat",
    "PHASE08_D14_PLIST_PARSED=1",
    "PHASE08_D14_PLIST_ROOT_DICT=1",
    "PHASE08_D14_PLIST_DICT_KEY_COUNT=2",
    "PHASE08_D14_PLIST_LABEL=org.rmxos.phase08.d14.noop",
    "PHASE08_D14_PLIST_PROGRAMARGUMENTS_COUNT=1",
    "PHASE08_D14_SOCKET_MATERIALIZE_CALLED=1",
    "PHASE08_D14_SOCKET_MATERIALIZE_SKIPPED=1",
    "PHASE08_D14_MATERIALIZED_FDS=0",
    "PHASE08_D14_SUBMIT_JOB_CALLED=1",
    "PHASE08_D14_REQUEST_KEY=SubmitJob",
    "PHASE08_D14_REQUEST_ENCODING=dictionary",
    "PHASE08_D14_LAUNCHCTL_PATH=plist_to_launch_msg_to_mig437",
    "PHASE08_D14_MIG_ROUTINE=ipc_request",
    "PHASE08_D14_MIG_ID=437",
    "PHASE08_D14_DIRECT_MIG_USED=0",
    "PHASE08_D14_MANAGEMENT_REQUEST_SENT=1",
    "PHASE08_D14_REPLY_RECEIVED=1",
    "PHASE08_D14_REPLY_ERRNO=0",
    "PHASE08_D14_LAUNCHCTL_EXIT=0",
    "PHASE08_D14_MANAGEMENT_CLIENT_STATUS=0",
    "PHASE08_D14_FILEPORT_MAKEPORT_CALLED=0",
    "PHASE08_D14_FILEPORT_MAKEFD_CALLED=0",
    "PHASE08_D14_VPROCMGR_GETSOCKET_CALLED=0",
    "PHASE08_D14_VPROCMGR_INIT_CALLED=0",
    "PHASE08_D14_VPROCMGR_MOVE_SUBSET_CALLED=0",
    "PHASE08_D14_VPROC_SWAP_INTEGER_CALLED=0",
    "PHASE08_D14_UDS_FALLBACK_USED=0",
    "PHASE08_D14_MIG_INFO_408_USED=0",
    "PHASE08_D14_XPC_PIPE_TRY_RECEIVE_CALLED=0",
    "PHASE08_D14_CALLER_PID_MATCH=1",
    "PHASE08_D14_DONOR_RUNTIME_DEMUX_CALLED=1",
    "PHASE08_D14_JOB_MIG_IPC_REQUEST=1",
    "PHASE08_D14_REQUEST_FDS_CNT=0",
    "PHASE08_D14_JOB_DO_IPC_REQUEST=1",
    "PHASE08_D14_SUBMITJOB_SEEN=1",
    "PHASE08_D14_JOB_IMPORT_CALLED=1",
    "PHASE08_D14_IMPORTED_LABEL=org.rmxos.phase08.d14.noop",
    "PHASE08_D14_DONOR_JOB_LABEL=org.rmxos.phase08.d14.noop",
    "PHASE08_D14_DONOR_JOB_LABEL_MATCH=1",
    "PHASE08_D14_JOB_CREATED=1",
    "PHASE08_D14_JOB_IMPORTED=1",
    "PHASE08_D14_RUNATLOAD_USED=0",
    "PHASE08_D14_KEEPALIVE_USED=0",
    "PHASE08_D14_MACHSERVICES_USED=0",
    "PHASE08_D14_SOCKETS_USED=0",
    "PHASE08_D14_GLOBAL_ON_DEMAND_CNT=0",
    "PHASE08_D14_JOB_DISPATCH_CALLED=1",
    "PHASE08_D14_JOB_DISPATCH_KICKSTART=0",
    "PHASE08_D14_JOB_DISPATCH_UFLAG=0",
    "PHASE08_D14_JOB_KEEPALIVE_CALLED=1",
    "PHASE08_D14_JOB_KEEPALIVE_RETURN=0",
    "PHASE08_D14_JOB_KEEPALIVE_REASON=none",
    "PHASE08_D14_JOB_START_CALLED=0",
    "PHASE08_D14_JOB_WATCHED=1",
    "PHASE08_D14_DONOR_JOB_FOUND=1",
    "PHASE08_D14_DONOR_JOB_PID=0",
    "PHASE08_D14_DONOR_JOB_ACTIVE=0",
    "PHASE08_D14_DONOR_JOB_ONDEMAND=1",
    "PHASE08_D14_DONOR_JOB_START_PENDING=0",
    "PHASE08_D14_LAUNCHCTL_PLIST_CONFIRMED=1",
    "PHASE08_D7_DISPATCH_MAIN_COMPLETION_SOURCE=dispatch_async_f",
    "phase08_dispatch_launchctl_plist_exit=0",
    "PHASE08_XPC_PIPE_TRY_RECEIVE_CALLED=0",
    "PHASE08_OLD_XPC_PIPE_RECEIVE_CALLED=0",
    "=== phase1 launchd harness end rc=0 ==="
  ]

  @required_regex_markers [
    %{
      "id" => "staged_libthr_regex",
      "pattern" => "PHASE08_STAGED_LIBTHR=/root/twq-lib/libthr\\.so\\.3",
      "sample" => "PHASE08_STAGED_LIBTHR=/root/twq-lib/libthr.so.3",
      "regex" => ~r/PHASE08_STAGED_LIBTHR=\/root\/twq-lib\/libthr\.so\.3/
    },
    %{
      "id" => "d14_bootstrap_port_reset",
      "pattern" => "PHASE08_D14_BOOTSTRAP_PORT_RESET=[1-9][0-9]* kr=0",
      "sample" => "PHASE08_D14_BOOTSTRAP_PORT_RESET=123 kr=0",
      "regex" => ~r/PHASE08_D14_BOOTSTRAP_PORT_RESET=[1-9][0-9]* kr=0/
    },
    %{
      "id" => "d14_plist_path",
      "pattern" =>
        "PHASE08_D14_PLIST_PATH=/root/nxplatform/phase1/org.rmxos.phase08.d14.noop.plist",
      "sample" =>
        "PHASE08_D14_PLIST_PATH=/root/nxplatform/phase1/org.rmxos.phase08.d14.noop.plist",
      "regex" =>
        ~r/PHASE08_D14_PLIST_PATH=\/root\/nxplatform\/phase1\/org\.rmxos\.phase08\.d14\.noop\.plist/
    },
    %{
      "id" => "d14_spawned_launchctl_pid",
      "pattern" => "phase08_dispatch_launchctl_plist_client_pid=[1-9][0-9]*",
      "sample" => "phase08_dispatch_launchctl_plist_client_pid=4242",
      "regex" => ~r/phase08_dispatch_launchctl_plist_client_pid=[1-9][0-9]*/
    },
    %{
      "id" => "d14_management_client_pid",
      "pattern" => "PHASE08_D14_MANAGEMENT_CLIENT_PID=[1-9][0-9]*",
      "sample" => "PHASE08_D14_MANAGEMENT_CLIENT_PID=4242",
      "regex" => ~r/PHASE08_D14_MANAGEMENT_CLIENT_PID=[1-9][0-9]*/
    },
    %{
      "id" => "d14_expected_management_client_pid",
      "pattern" => "PHASE08_D14_EXPECTED_MANAGEMENT_CLIENT_PID=[1-9][0-9]*",
      "sample" => "PHASE08_D14_EXPECTED_MANAGEMENT_CLIENT_PID=4242",
      "regex" => ~r/PHASE08_D14_EXPECTED_MANAGEMENT_CLIENT_PID=[1-9][0-9]*/
    },
    %{
      "id" => "d14_caller_audit_pid",
      "pattern" => "PHASE08_D14_CALLER_AUDIT_PID=[1-9][0-9]*",
      "sample" => "PHASE08_D14_CALLER_AUDIT_PID=4242",
      "regex" => ~r/PHASE08_D14_CALLER_AUDIT_PID=[1-9][0-9]*/
    },
    %{
      "id" => "d14_security_session_injected",
      "pattern" => "PHASE08_D14_SECURITY_SESSION_INJECTED=[01]",
      "sample" => "PHASE08_D14_SECURITY_SESSION_INJECTED=0",
      "regex" => ~r/PHASE08_D14_SECURITY_SESSION_INJECTED=[01]/
    }
  ]

  @required_order_tail [
    "phase08_dispatch_launchctl_plist_start",
    "PHASE08_D14_UFLAG_FORCED_ZERO=1",
    "PHASE08_D14_MANAGEMENT_REQUEST_SENT=1",
    "PHASE08_D14_CALLER_PID_MATCH=1",
    "PHASE08_D14_DONOR_RUNTIME_DEMUX_CALLED=1",
    "PHASE08_D14_SUBMITJOB_SEEN=1",
    "PHASE08_D14_JOB_IMPORT_CALLED=1",
    "PHASE08_D14_JOB_DISPATCH_CALLED=1",
    "PHASE08_D14_JOB_WATCHED=1",
    "PHASE08_D14_LAUNCHCTL_PLIST_CONFIRMED=1",
    "PHASE08_D7_DISPATCH_MAIN_COMPLETION_SOURCE=dispatch_async_f"
  ]

  @kernel_hard_stop_patterns [
    {"fatal_signal", ~r/PHASE08_FATAL_SIGNAL/},
    {"sigsys", ~r/SIGSYS/},
    {"bad_system_call", ~r/Bad system call/},
    {"unknown_freebsd_syscall", ~r/UNKNOWN FreeBSD SYSCALL/},
    {"signal_12", ~r/Signal 12|signal = 12/},
    {"nosys", ~r/nosys [0-9]+/},
    {"panic", ~r/panic:/},
    {"fatal_trap", ~r/Fatal trap/},
    {"witness_or_lock_order", ~r/WITNESS:|WITNESS.*lock order|lock order reversal/},
    {"sleeping_thread", ~r/Sleeping thread/},
    {"kdb_backtrace", ~r/KDB: stack backtrace/},
    {"kassert", ~r/KASSERT/}
  ]

  @inherited_failure_patterns [
    {"d4_d12_inherited_failure",
     ~r/PHASE08_D4B_TRAILER_BAD_TYPE=1|PHASE08_D4B_TRAILER_TOO_SMALL=1|PHASE08_D4B_CALLER_CREDS_VALID=0|PHASE08_D5_DONOR_TERMINAL_STATE=missing|PHASE08_D4_DONOR_SERVICE_MISSING=1|PHASE08_D6_DONOR_SERVICE_MISSING=1|PHASE08_D6_SECOND_CHECKIN_TIMEOUT=1|PHASE08_D6_SECOND_LOOKUP_TIMEOUT=1|PHASE08_D9_DONOR_PROC_EVENT_MISSING_EXIT=1|PHASE08_D9_DONOR_PROC_EVENT_JOB_FOUND=0|PHASE08_D9_DONOR_PROC_EVENT_SERVICE_MATCH=0|PHASE08_D9_DONOR_PROC_EVENT_BRIDGE_RESULT=0|PHASE08_D10_SUPERVISION_RECORD=0|PHASE08_D10_SERVICE_FOUND=0|PHASE08_D10_SERVICE_NAME_MATCH=0|PHASE08_D10_FIRST_OWNER_PID_MATCH=0|PHASE08_D10_FIRST_OWNER_REAPED=0|PHASE08_D10_FIRST_OWNER_CLEARED=0|PHASE08_D10_REPLACEMENT_OWNER_PID_MATCH=0|PHASE08_D10_REPLACEMENT_OWNER_JOB=0|PHASE08_D10_REPLACEMENT_OWNER_CHECKEDIN=0|PHASE08_D10_REPLACEMENT_MESSAGE_DELIVERED=0|PHASE08_D10_DONOR_PROC_EVENT_BRIDGE=0|PHASE08_D10_XPC_PIPE_TRY_RECEIVE_CALLED=[1-9][0-9]*|PHASE08_D10_SUPERVISION_CONFIRMED=0|PHASE08_D11_REPLY_RECEIVED=0|PHASE08_D11_REPLY_REPEAT_OK=0|PHASE08_D11_REPLY_ERRNO=[1-9][0-9]*|PHASE08_D11_REPLY_FD_OBJECTS=[1-9][0-9]*|PHASE08_D11_FILEPORT_MAKEPORT_CALLED=[1-9][0-9]*|PHASE08_D11_FILEPORT_MAKEFD_CALLED=[1-9][0-9]*|PHASE08_D11_VPROCMGR_GETSOCKET_CALLED=[1-9][0-9]*|PHASE08_D11_VPROCMGR_INIT_CALLED=[1-9][0-9]*|PHASE08_D11_VPROCMGR_MOVE_SUBSET_CALLED=[1-9][0-9]*|PHASE08_D11_MIG_INFO_408_USED=1|PHASE08_D11_XPC_PIPE_TRY_RECEIVE_CALLED=[1-9][0-9]*|PHASE08_D11_LAUNCHCTL_REQUEST_CONFIRMED=0|PHASE08_D11_MANAGEMENT_REQUEST_TIMEOUT=1|PHASE08_D11B_REPLY_RECEIVED=0|PHASE08_D11B_REPLY_ERRNO=[1-9][0-9]*|PHASE08_D11B_REPLY_FD_OBJECTS=[1-9][0-9]*|PHASE08_D11B_REQUEST_FD_OBJECTS=[1-9][0-9]*|PHASE08_D11B_FILEPORT_MAKEPORT_CALLED=[1-9][0-9]*|PHASE08_D11B_FILEPORT_MAKEFD_CALLED=[1-9][0-9]*|PHASE08_D11B_VPROCMGR_GETSOCKET_CALLED=[1-9][0-9]*|PHASE08_D11B_VPROCMGR_INIT_CALLED=[1-9][0-9]*|PHASE08_D11B_VPROCMGR_MOVE_SUBSET_CALLED=[1-9][0-9]*|PHASE08_D11B_MIG_INFO_408_USED=1|PHASE08_D11B_XPC_PIPE_TRY_RECEIVE_CALLED=[1-9][0-9]*|PHASE08_D11B_JOB_START_CALLED=1|PHASE08_D11B_SHOULD_NOT_RUN_EXECUTED=1|PHASE08_D11B_SUBMITJOB_CONFIRMED=0|PHASE08_D11B_MANAGEMENT_REQUEST_TIMEOUT=1|PHASE08_PROC_SOURCE_REGISTER_TIMEOUT|PHASE08_PROC_SOURCE_EVENT_TIMEOUT|PHASE08_PROC_SOURCE_MISSING_EXIT_FLAG|PHASE08_PROC_SOURCE_DUPLICATE_EVENT|PHASE08_SERVICE_STOP_KILL_FAILED|PHASE08_SERVICE_WAITPID_STATUS=error|PHASE08_BOOTSTRAP_SERVER_CHECKIN=timeout|PHASE08_SERVICE_CHECKIN_STATE_TIMEOUT=1|PHASE08_D12_REPLY_RECEIVED=0|PHASE08_D12_REPLY_ERRNO=[1-9][0-9]*|PHASE08_D12_REQUEST_FD_OBJECTS=[1-9][0-9]*|PHASE08_D12_REPLY_FD_OBJECTS=[1-9][0-9]*|PHASE08_D12_FILEPORT_MAKEPORT_CALLED=[1-9][0-9]*|PHASE08_D12_FILEPORT_MAKEFD_CALLED=[1-9][0-9]*|PHASE08_D12_VPROCMGR_GETSOCKET_CALLED=[1-9][0-9]*|PHASE08_D12_VPROCMGR_INIT_CALLED=[1-9][0-9]*|PHASE08_D12_VPROCMGR_MOVE_SUBSET_CALLED=[1-9][0-9]*|PHASE08_D12_MIG_INFO_408_USED=1|PHASE08_D12_XPC_PIPE_TRY_RECEIVE_CALLED=[1-9][0-9]*|PHASE08_D12_MANAGEMENT_REQUEST_TIMEOUT=1|PHASE08_D12_GLOBAL_ON_DEMAND_CNT=[1-9][0-9]*|PHASE08_D12_JOB_DISPATCH_UFLAG=1|PHASE08_D12_JOB_KEEPALIVE_RETURN=0|PHASE08_D12_PROC_SOURCE_REGISTER_TIMEOUT=1|PHASE08_D12_PROC_SOURCE_EVENT_TIMEOUT=1|PHASE08_D12_PROC_SOURCE_NOTE_EXIT=0|PHASE08_D12_DONOR_REAP_BRIDGE_RESULT=0|PHASE08_D12_DONOR_JOB_EXIT_STATUS=[1-9][0-9]*|PHASE08_D12_RUNATLOAD_EXECUTED_PID_MATCH=0|PHASE08_D12_JOB_RESTARTED=1|PHASE08_D12_RESTART_ATTEMPTED=1|PHASE08_D12_RUNATLOAD_CONFIRMED=0|PHASE08_D12_UFLAG_RESTORED=0/},
    {"d13_failure",
     ~r/PHASE08_D13_REPLY_RECEIVED=0|PHASE08_D13_REPLY_ERRNO=[1-9][0-9]*|PHASE08_D13_REQUEST_FD_OBJECTS=[1-9][0-9]*|PHASE08_D13_REPLY_FD_OBJECTS=[1-9][0-9]*|PHASE08_D13_FILEPORT_MAKEPORT_CALLED=[1-9][0-9]*|PHASE08_D13_FILEPORT_MAKEFD_CALLED=[1-9][0-9]*|PHASE08_D13_VPROCMGR_GETSOCKET_CALLED=[1-9][0-9]*|PHASE08_D13_VPROCMGR_INIT_CALLED=[1-9][0-9]*|PHASE08_D13_VPROCMGR_MOVE_SUBSET_CALLED=[1-9][0-9]*|PHASE08_D13_MIG_INFO_408_USED=1|PHASE08_D13_MANAGEMENT_REQUEST_TIMEOUT=1|PHASE08_D13_GLOBAL_ON_DEMAND_CNT=[1-9][0-9]*|PHASE08_D13_JOB_DISPATCH_UFLAG=1|PHASE08_D13_JOB_KEEPALIVE_RETURN=0|PHASE08_D13_SPAWN_EXECUTED=0|PHASE08_D13_SPAWN_EXECUTED_PID_MATCH=0|PHASE08_D13_PROC_SOURCE_EVENT_TIMEOUT=1|PHASE08_D13_PROC_SOURCE_NOTE_EXIT=0|PHASE08_D13_DONOR_REAP_BRIDGE_RESULT=0|PHASE08_D13_DONOR_JOB_EXIT_STATUS=[1-9][0-9]*|PHASE08_D13_JOB_RESTARTED=1|PHASE08_D13_SPAWN_LABEL_CONFIRMED=0|PHASE08_D13_SPAWN_GENERALIZATION_CONFIRMED=0|PHASE08_D13_UFLAG_RESTORED=0/}
  ]

  @d14_failure_patterns [
    {"d14_failure",
     ~r/PHASE08_D14_REPLY_RECEIVED=0|PHASE08_D14_REPLY_ERRNO=[1-9][0-9]*|PHASE08_D14_JOB_START_CALLED=1|PHASE08_D14_SHOULD_NOT_RUN_EXECUTED=1|PHASE08_D14_UFLAG_RESTORED=0|PHASE08_D14_UFLAG_DURING_DISPATCH=1|PHASE08_D14_JOB_DISPATCH_UFLAG=1|PHASE08_D14_DONOR_JOB_PREEXISTING=1|PHASE08_D14_JSON_ADAPTER_USED=1|PHASE08_D14_UDS_FALLBACK_USED=1|PHASE08_D14_FILEPORT_MAKEPORT_CALLED=[1-9][0-9]*|PHASE08_D14_FILEPORT_MAKEFD_CALLED=[1-9][0-9]*|PHASE08_D14_VPROCMGR_GETSOCKET_CALLED=[1-9][0-9]*|PHASE08_D14_VPROCMGR_INIT_CALLED=[1-9][0-9]*|PHASE08_D14_VPROCMGR_MOVE_SUBSET_CALLED=[1-9][0-9]*|PHASE08_D14_VPROC_SWAP_INTEGER_CALLED=[1-9][0-9]*|PHASE08_D14_MIG_INFO_408_USED=1|PHASE08_D14_MANAGEMENT_REQUEST_TIMEOUT=1|PHASE08_D14_LAUNCHCTL_PLIST_CONFIRMED=0|PHASE08_D14_LOAD_SUBCOMMAND=0|PHASE08_D14_SOCKET_MATERIALIZE_SKIPPED=0|PHASE08_D14_MATERIALIZED_FDS=[1-9][0-9]*|PHASE08_D14_GLOBAL_ON_DEMAND_CNT=[1-9][0-9]*|PHASE08_D14_JOB_KEEPALIVE_RETURN=1/}
  ]

  def run(opts \\ []) do
    legacy_repo = Keyword.get(opts, :legacy_repo, @default_legacy_repo)
    legacy_ref = Keyword.get(opts, :legacy_ref, @default_legacy_ref)
    oracle_repo = Keyword.get(opts, :oracle_repo, @default_oracle_repo)
    out_root = Keyword.get(opts, :out_root, Path.join(oracle_repo, "priv/runs/migration-parity"))
    env_path = Keyword.get(opts, :env_path, "priv/env/env.local")
    lane = Keyword.get(opts, :lane, "launchd")

    evidence_dir = Keyword.get_lazy(opts, :evidence_dir, fn -> default_evidence_dir(out_root) end)
    File.mkdir_p!(evidence_dir)

    legacy_commit = resolve_legacy_commit!(legacy_repo, legacy_ref)
    oracle_commit = git!(oracle_repo, ["rev-parse", "--short", "HEAD"])
    legacy_hashes = hash_legacy_files!(legacy_repo, legacy_commit)
    oracle_hashes = hash_oracle_files!(oracle_repo)

    tool_provenance =
      external_tool_provenance(legacy_repo, legacy_ref, legacy_commit, legacy_hashes)

    CanonicalJSON.write!(Path.join(evidence_dir, "legacy_hashes.json"), %{
      "schema" => "rmxos_oracle.migration.legacy_hashes.v1",
      "legacy_repo" => legacy_repo,
      "legacy_ref" => legacy_ref,
      "dereferenced_commit" => legacy_commit,
      "contract_mode" => "legacy_contract_reference",
      "legacy_executable_run" => false,
      "files" => legacy_hashes
    })

    CanonicalJSON.write!(Path.join(evidence_dir, "oracle_hashes.json"), %{
      "schema" => "rmxos_oracle.migration.oracle_hashes.v1",
      "oracle_repo" => oracle_repo,
      "oracle_commit" => oracle_commit,
      "files" => oracle_hashes
    })

    CanonicalJSON.write!(
      Path.join(evidence_dir, "external_tool_provenance.json"),
      tool_provenance
    )

    env_result = resolve_env(lane, env_path, evidence_dir)
    CanonicalJSON.write!(Path.join(evidence_dir, "env_resolved.json"), env_result)

    command_result =
      if env_result["passed"] and tool_provenance["passed"] do
        run_guest_execution(legacy_repo, env_result, evidence_dir)
      else
        %{
          "schema" => "rmxos_oracle.migration.d14.guest_execution.v1",
          "passed" => false,
          "skipped" => true,
          "errors" => env_result["errors"] ++ tool_provenance["errors"],
          "external_tool_mode" => tool_provenance["external_tool_mode"]
        }
      end

    log = read_serial_log(env_result)
    hard_stop_scan = if log, do: hard_stop_scan(log), else: not_run_report("hard_stop_scan")

    marker_comparison =
      if log, do: validate_serial_log(log), else: not_run_report("marker_comparison")

    boot_identity = boot_identity(env_result, log, legacy_commit, oracle_commit)

    negative_control =
      if marker_comparison["passed"] do
        run_negative_control!(log, evidence_dir)
      else
        %{
          "schema" => "rmxos_oracle.migration.d14.negative_control.v1",
          "passed" => false,
          "skipped" => true,
          "reason" => "marker comparison did not pass"
        }
      end

    CanonicalJSON.write!(Path.join(evidence_dir, "hard_stop_scan.json"), hard_stop_scan)
    CanonicalJSON.write!(Path.join(evidence_dir, "marker_comparison.json"), marker_comparison)
    CanonicalJSON.write!(Path.join(evidence_dir, "boot_identity.json"), boot_identity)
    CanonicalJSON.write!(Path.join(evidence_dir, "negative_control.json"), negative_control)

    result =
      if env_result["passed"] and tool_provenance["passed"] and command_result["passed"] and
           boot_identity["passed"] and
           marker_comparison["passed"] and hard_stop_scan["passed"] and negative_control["passed"] do
        "parity_passed"
      else
        "parity_failed"
      end

    parity = %{
      "schema" => "rmxos_oracle.migration.parity.raw_evidence.v1",
      "slice_id" => @slice_id,
      "result" => result,
      "comparison_axis" => "legacy_vs_oracle",
      "contract_mode" => "legacy_contract_reference",
      "legacy_executable_run" => false,
      "observation_basis" => "L2_guest_integration",
      "normalization_rule" => %{
        "id" => "phase08.d14.launchctl_plist_inert_load.markers.v1",
        "description" =>
          "Compare oracle-owned guest run against the immutable D14 marker contract, hard-stop denylist, boot identity, and D14 state invariants."
      },
      "legacy_contract_source_ref" => legacy_contract_source_ref(),
      "legacy_test_commit" => legacy_commit,
      "oracle_commit" => oracle_commit,
      "freebsd_src_commit" => env_result["freebsd_src_commit"],
      "legacy" => %{
        "repo" => legacy_repo,
        "ref" => legacy_ref,
        "dereferenced_commit" => legacy_commit,
        "expected_dereferenced_commit" => @expected_legacy_commit,
        "file_hashes" => legacy_hashes
      },
      "oracle" => %{
        "repo" => oracle_repo,
        "commit" => oracle_commit,
        "file_hashes" => oracle_hashes
      },
      "environment" => %{"path" => "env_resolved.json", "passed" => env_result["passed"]},
      "external_tool_provenance" => %{
        "path" => "external_tool_provenance.json",
        "passed" => tool_provenance["passed"],
        "external_tool_mode" => tool_provenance["external_tool_mode"]
      },
      "guest_execution" => command_result,
      "boot_identity" => %{"path" => "boot_identity.json", "passed" => boot_identity["passed"]},
      "marker_comparison" => %{
        "path" => "marker_comparison.json",
        "passed" => marker_comparison["passed"]
      },
      "hard_stop_scan" => %{"path" => "hard_stop_scan.json", "passed" => hard_stop_scan["passed"]},
      "negative_control" => %{
        "path" => "negative_control.json",
        "passed" => negative_control["passed"]
      },
      "evidence_files" => evidence_files(evidence_dir),
      "limitations" => [
        "No certification claim is created.",
        "Legacy verifier is not executed because repo-root fallback would confound objdir attribution.",
        "Shell build/stage/run tools are transitional.",
        "This result is not canonical while shell tools remain in the runtime path."
      ]
    }

    CanonicalJSON.write!(Path.join(evidence_dir, "parity.json"), parity)

    %{
      "status" => result,
      "parity_passed" => result == "parity_passed",
      "evidence_dir" => evidence_dir,
      "legacy_commit" => legacy_commit,
      "oracle_commit" => oracle_commit,
      "behavior_passed" => marker_comparison["passed"],
      "negative_api_passed" => negative_control["passed"],
      "negative_mix_test_passed" => negative_control["passed"],
      "boot_identity_passed" => boot_identity["passed"],
      "marker_comparison_passed" => marker_comparison["passed"],
      "hard_stop_scan_passed" => hard_stop_scan["passed"],
      "negative_control_passed" => negative_control["passed"]
    }
  end

  def slice_id, do: @slice_id
  def required_exact_markers, do: @required_exact_markers
  def required_regex_marker_samples, do: Enum.map(@required_regex_markers, & &1["sample"])

  def validate_serial_log(log) when is_binary(log) do
    exact_checks =
      Enum.map(@required_exact_markers, fn marker ->
        %{
          "kind" => "exact",
          "marker" => marker,
          "passed" => String.contains?(log, marker)
        }
      end)

    regex_checks =
      Enum.map(@required_regex_markers, fn spec ->
        %{
          "kind" => "regex",
          "id" => spec["id"],
          "pattern" => spec["pattern"],
          "passed" => Regex.match?(spec["regex"], log)
        }
      end)

    order_check = order_check(log, @required_order_tail)
    invariant_checks = invariant_checks(log)
    checks = exact_checks ++ regex_checks ++ [order_check] ++ invariant_checks

    %{
      "schema" => "rmxos_oracle.migration.d14.marker_comparison.v1",
      "passed" => Enum.all?(checks, & &1["passed"]),
      "required_exact_count" => length(@required_exact_markers),
      "required_regex_count" => length(@required_regex_markers),
      "checks" => checks,
      "missing" =>
        checks
        |> Enum.reject(& &1["passed"])
        |> Enum.map(&Map.take(&1, ~w(kind marker id pattern reason)))
    }
  end

  def hard_stop_scan(log) when is_binary(log) do
    groups = [
      {"kernel_system", @kernel_hard_stop_patterns},
      {"inherited_d1_d13", @inherited_failure_patterns},
      {"d14", @d14_failure_patterns}
    ]

    scans =
      Enum.flat_map(groups, fn {group, patterns} ->
        Enum.map(patterns, fn {id, regex} ->
          matches =
            regex
            |> Regex.scan(log)
            |> Enum.map(fn [match | _captures] -> match end)
            |> Enum.uniq()

          %{
            "group" => group,
            "id" => id,
            "pattern" => inspect(regex),
            "matched" => matches != [],
            "matches" => matches
          }
        end)
      end)

    %{
      "schema" => "rmxos_oracle.migration.d14.hard_stop_scan.v1",
      "denylist_source_ref" => legacy_contract_source_ref(),
      "passed" => Enum.all?(scans, &(not &1["matched"])),
      "scans" => scans,
      "matches" => Enum.filter(scans, & &1["matched"])
    }
  end

  def boot_identity(
        env_result,
        log,
        legacy_test_commit \\ @expected_legacy_commit,
        oracle_commit \\ nil
      ) do
    env = env_result["resolved"] || %{}
    serial_loaded = is_binary(log) and String.contains?(log, "mach_module=loaded")
    kernel = file_identity(env["kernel_path"])
    mach_ko = file_identity(env["mach_ko_path"])
    guest_image = file_identity(env["vm_image"])

    hash_requirements = [
      %{"id" => "kernel_sha256_present", "passed" => hash_present?(kernel)},
      %{"id" => "mach_ko_sha256_present", "passed" => hash_present?(mach_ko)},
      %{"id" => "guest_image_sha256_present", "passed" => hash_present?(guest_image)}
    ]

    %{
      "schema" => "rmxos_oracle.migration.boot_identity.v1",
      "freebsd_src_commit" => env_result["freebsd_src_commit"],
      "freebsd_src_commit_meaning" =>
        "git rev-parse --short HEAD in NXPLATFORM_FREEBSD_SRC, not the oracle parity test commit",
      "legacy_test_commit" => legacy_test_commit,
      "oracle_commit" => oracle_commit,
      "rx_source_ref" => env["base_profile"],
      "freebsd_src" => env["NXPLATFORM_FREEBSD_SRC"],
      "kernel_objdirprefix" => env["NXPLATFORM_KERNEL_OBJDIRPREFIX"],
      "kernel_conf" => env["NXPLATFORM_KERNEL_CONF"],
      "kernel" => kernel,
      "mach_ko" => mach_ko,
      "guest_image" => guest_image,
      "serial_markers" => %{"mach_module" => if(serial_loaded, do: "loaded", else: nil)},
      "hash_requirements" => hash_requirements,
      "reviewed_exceptions" => [],
      "passed" => serial_loaded and Enum.all?(hash_requirements, & &1["passed"])
    }
  end

  def run_negative_control!(log, evidence_dir) do
    mutated =
      log
      |> String.split("\n")
      |> Enum.reject(&String.contains?(&1, "PHASE08_D14_LAUNCHCTL_PLIST_CONFIRMED=1"))
      |> Enum.join("\n")

    mutated_path = Path.join(evidence_dir, "negative_control_serial_missing_d14_confirmed.log")
    File.write!(mutated_path, mutated)

    report = validate_serial_log(mutated)

    marker_specific_failure? =
      Enum.any?(report["missing"], fn missing ->
        missing["marker"] == "PHASE08_D14_LAUNCHCTL_PLIST_CONFIRMED=1"
      end)

    %{
      "schema" => "rmxos_oracle.migration.d14.negative_control.v1",
      "control" => "serial_log_missing_required_d14_confirmed_marker",
      "passed" => report["passed"] == false and marker_specific_failure?,
      "validator_passed" => report["passed"],
      "expected_failure_marker" => "PHASE08_D14_LAUNCHCTL_PLIST_CONFIRMED=1",
      "marker_specific_failure" => marker_specific_failure?,
      "mutated_log_path" => Path.basename(mutated_path),
      "limitation" => "This proves verifier red-path, not guest behavior red-path."
    }
  end

  defp external_tool_provenance(legacy_repo, legacy_ref, legacy_commit, legacy_hashes) do
    legacy_by_path = Map.new(legacy_hashes, fn entry -> {entry["path"], entry} end)

    tools =
      Enum.map(@executed_tool_paths, fn path ->
        current_path = Path.join(legacy_repo, path)
        tag_sha256 = get_in(legacy_by_path, [path, "sha256"])
        current_sha256 = if File.regular?(current_path), do: sha256_file(current_path)

        %{
          "path" => path,
          "executed_from" => current_path,
          "legacy_ref" => legacy_ref,
          "legacy_test_commit" => legacy_commit,
          "tag_sha256" => tag_sha256,
          "current_sha256" => current_sha256,
          "current_exists" => File.regular?(current_path),
          "matches_tag" => is_binary(current_sha256) and current_sha256 == tag_sha256
        }
      end)

    runtime_inputs =
      Enum.map([@fixture_path], fn path ->
        current_path = Path.join(legacy_repo, path)
        tag_sha256 = get_in(legacy_by_path, [path, "sha256"])
        current_sha256 = if File.regular?(current_path), do: sha256_file(current_path)

        %{
          "path" => path,
          "used_from" => current_path,
          "legacy_ref" => legacy_ref,
          "legacy_test_commit" => legacy_commit,
          "tag_sha256" => tag_sha256,
          "current_sha256" => current_sha256,
          "current_exists" => File.regular?(current_path),
          "matches_tag" => is_binary(current_sha256) and current_sha256 == tag_sha256
        }
      end)

    tool_errors =
      tools
      |> Enum.reject(& &1["matches_tag"])
      |> Enum.map(fn tool ->
        cond do
          not tool["current_exists"] ->
            "external tool missing from source tree: #{tool["path"]}"

          not is_binary(tool["tag_sha256"]) ->
            "external tool missing tag hash in legacy_hashes.json: #{tool["path"]}"

          true ->
            "external tool differs from #{legacy_ref}^{commit}: #{tool["path"]}"
        end
      end)

    input_errors =
      runtime_inputs
      |> Enum.reject(& &1["matches_tag"])
      |> Enum.map(fn input ->
        cond do
          not input["current_exists"] ->
            "external runtime input missing from source tree: #{input["path"]}"

          not is_binary(input["tag_sha256"]) ->
            "external runtime input missing tag hash in legacy_hashes.json: #{input["path"]}"

          true ->
            "external runtime input differs from #{legacy_ref}^{commit}: #{input["path"]}"
        end
      end)

    errors = tool_errors ++ input_errors

    %{
      "schema" => "rmxos_oracle.migration.d14.external_tool_provenance.v1",
      "external_tool_mode" => "source_tree_with_sha256_enforcement",
      "mode_description" =>
        "D14 executes source-tree transitional scripts only after current bytes match oracle-parity-a30ef3f^{commit}.",
      "legacy_repo" => legacy_repo,
      "legacy_ref" => legacy_ref,
      "legacy_test_commit" => legacy_commit,
      "passed" => errors == [],
      "tools" => tools,
      "runtime_inputs" => runtime_inputs,
      "errors" => errors
    }
  end

  defp resolve_env(lane, env_path, evidence_dir) do
    env_check = Env.check(lane, env_path: env_path)
    env = Env.load(env_path)
    errors = env_check["errors"] ++ extra_env_errors(env, env_check, evidence_dir)

    resolved =
      if errors == [] do
        resolved_d14_env(env, env_check, evidence_dir)
      else
        %{}
      end

    %{
      "schema" => "rmxos_oracle.migration.d14.env_resolved.v1",
      "passed" => errors == [],
      "lane" => lane,
      "env_path" => env_path,
      "freebsd_src_commit" => env_check["rmxos_source_commit"],
      "base_env_check" => env_check,
      "resolved" => resolved,
      "projected_env" =>
        Map.take(resolved, [
          "NXPLATFORM_KERNEL_OBJDIRPREFIX",
          "MAKEOBJDIRPREFIX",
          "NXPLATFORM_FREEBSD_SRC",
          "NXPLATFORM_SERIAL_LOG"
        ]),
      "errors" => errors
    }
  end

  defp extra_env_errors(env, env_check, evidence_dir) do
    required = [
      "NXPLATFORM_ARTIFACTS_DIR",
      "NXPLATFORM_PHASE1_LAUNCHD_HARNESS_WORKDIR",
      "NXPLATFORM_PHASE07_LIBDISPATCH_DIR"
    ]

    required_errors =
      Enum.flat_map(required, fn key ->
        validate_required_path(key, Map.get(env, key))
      end)

    prefix = env_check["kernel_objdirprefix"]
    serial_log = Path.join(evidence_dir, "oracle_serial.log")

    projection_errors =
      cond do
        not is_binary(prefix) or prefix == "" ->
          ["missing selected launchd objdir prefix projection"]

        Regex.match?(~r/\$\{[^}]+\}/, prefix) ->
          ["selected launchd objdir prefix contains unresolved placeholder: #{prefix}"]

        not File.dir?(prefix) ->
          ["selected launchd objdir prefix does not exist: #{prefix}"]

        true ->
          []
      end

    serial_errors =
      if Paths.under?(serial_log, Path.join(Paths.oracle_root(), "priv/runs")) do
        []
      else
        ["serial log path must remain under ignored priv/runs: #{serial_log}"]
      end

    required_errors ++ projection_errors ++ serial_errors
  end

  defp validate_required_path(key, value) do
    cond do
      not is_binary(value) or value == "" ->
        ["missing #{key}"]

      Regex.match?(~r/\$\{[^}]+\}/, value) ->
        ["#{key} contains unresolved placeholder: #{value}"]

      not Paths.absolute?(value) ->
        ["#{key} must be absolute: #{value}"]

      key in ["NXPLATFORM_PHASE07_LIBDISPATCH_DIR"] and not File.dir?(value) ->
        ["#{key} does not exist: #{value}"]

      key == "NXPLATFORM_ARTIFACTS_DIR" and not path_or_parent_ok?(value) ->
        ["#{key} parent is not creatable: #{value}"]

      key == "NXPLATFORM_PHASE1_LAUNCHD_HARNESS_WORKDIR" and not path_or_parent_ok?(value) ->
        ["#{key} parent is not creatable: #{value}"]

      true ->
        []
    end
  end

  defp path_or_parent_ok?(path), do: File.dir?(path) or File.dir?(Path.dirname(path))

  defp resolved_d14_env(env, env_check, evidence_dir) do
    workspace_root = env_check["workspace_root"]
    freebsd_src = env_check["freebsd_src"]
    prefix = env_check["kernel_objdirprefix"]
    vm_name = Map.get(env, "NXPLATFORM_VM_NAME", "nxplatform-dev")
    vm_image = Map.get(env, "NXPLATFORM_VM_IMAGE", "#{workspace_root}/vm/runs/#{vm_name}.img")
    kernel_conf = Map.get(env, "NXPLATFORM_KERNEL_CONF", @kernel_conf_default)
    serial_log = Path.join(evidence_dir, "oracle_serial.log")

    %{
      "NXPLATFORM_WORKSPACE_ROOT" => workspace_root,
      "NXPLATFORM_FREEBSD_SRC" => freebsd_src,
      "NXPLATFORM_KERNEL_OBJDIRPREFIX" => prefix,
      "MAKEOBJDIRPREFIX" => prefix,
      "NXPLATFORM_ARTIFACTS_DIR" => Map.fetch!(env, "NXPLATFORM_ARTIFACTS_DIR"),
      "NXPLATFORM_PHASE1_LAUNCHD_HARNESS_WORKDIR" =>
        Map.fetch!(env, "NXPLATFORM_PHASE1_LAUNCHD_HARNESS_WORKDIR"),
      "NXPLATFORM_PHASE07_LIBDISPATCH_DIR" =>
        Map.fetch!(env, "NXPLATFORM_PHASE07_LIBDISPATCH_DIR"),
      "NXPLATFORM_SERIAL_LOG" => serial_log,
      "NXPLATFORM_PHASE08_LAUNCHD_DISPATCH_LAUNCHCTL_PLIST_SERIAL_LOG" => serial_log,
      "NXPLATFORM_KERNEL_CONF" => kernel_conf,
      "NXPLATFORM_EXPECT_KERNEL" => Map.get(env, "NXPLATFORM_EXPECT_KERNEL", kernel_conf),
      "NXPLATFORM_VM_NAME" => vm_name,
      "NXPLATFORM_VM_IMAGE" => vm_image,
      "NXPLATFORM_PHASE1_LAUNCHD_HARNESS_TIMEOUT" =>
        Map.get(env, "NXPLATFORM_PHASE1_LAUNCHD_HARNESS_TIMEOUT", "80"),
      "NXPLATFORM_PHASE08_LAUNCHD_DISPATCH_REBUILD" =>
        Map.get(env, "NXPLATFORM_PHASE08_LAUNCHD_DISPATCH_REBUILD", "0"),
      "NXPLATFORM_LAUNCHD_HARNESS_SKIP_COMPILE" =>
        Map.get(env, "NXPLATFORM_LAUNCHD_HARNESS_SKIP_COMPILE", "0"),
      "base_profile" => env_check["base_profile"],
      "freebsd_src_commit" => env_check["rmxos_source_commit"],
      "kernel_path" => "#{prefix}#{freebsd_src}/amd64.amd64/sys/#{kernel_conf}/kernel",
      "mach_ko_path" => "#{prefix}#{freebsd_src}/amd64.amd64/sys/modules/mach/mach.ko",
      "vm_image" => vm_image
    }
  end

  defp run_guest_execution(legacy_repo, env_result, evidence_dir) do
    env = env_result["resolved"]
    host_log = Path.join(evidence_dir, "oracle_host.log")
    File.write!(host_log, "")

    script = fn path -> Path.join(legacy_repo, path) end

    dispatch_archive =
      Path.join(
        env["NXPLATFORM_PHASE07_LIBDISPATCH_DIR"],
        "libdispatch_phase07_link_policy_archive.a"
      )

    rebuild_dispatch? = env["NXPLATFORM_PHASE08_LAUNCHD_DISPATCH_REBUILD"] == "1"

    commands =
      [
        {"build minibootstrap support objects",
         script.("scripts/bhyve/build-phase1-minibootstrap.sh"), []},
        {"build donor bootstrap tests", script.("scripts/launchd/build-bootstrap-donor-tests.sh"),
         []},
        {"build D14 launchctl", script.("scripts/launchd/build-phase08-d14-launchctl.sh"), []},
        {"build Mach module", "make",
         ["-C", "#{env["NXPLATFORM_FREEBSD_SRC"]}/sys/modules/mach", "all"]}
      ] ++
        dispatch_commands(rebuild_dispatch?, dispatch_archive, script) ++
        [
          {"link dispatch-launchctl-plist harness",
           script.("scripts/launchd/link-launchd-harness.sh"), [],
           [
             {"NXPLATFORM_LAUNCHD_HARNESS_MODE", "dispatch-launchctl-plist"},
             {"NXPLATFORM_LAUNCHD_HARNESS_SKIP_COMPILE",
              env["NXPLATFORM_LAUNCHD_HARNESS_SKIP_COMPILE"]}
           ]},
          {"stage dispatch-launchctl-plist harness guest",
           script.("scripts/bhyve/stage-phase1-launchd-harness-guest.sh"), [],
           [
             {"NXPLATFORM_PHASE1_LAUNCHD_HARNESS_MODE", "dispatch-launchctl-plist"},
             {"NXPLATFORM_PHASE1_LAUNCHD_HARNESS_REBUILD", "0"},
             {"NXPLATFORM_INSTALL_MACH_MODULE", "1"},
             {"NXPLATFORM_PHASE1_LAUNCHD_HARNESS_TIMEOUT",
              env["NXPLATFORM_PHASE1_LAUNCHD_HARNESS_TIMEOUT"]}
           ]},
          {"run guest", script.("scripts/bhyve/run-guest.sh"), []}
        ]

    {records, hard_failed?} =
      Enum.reduce_while(commands, {[], false}, fn command, {records, _failed?} ->
        record = run_command(command, env, host_log)
        records = records ++ [record]

        if record["exit_status"] == 0 or record["label"] == "run guest" do
          {:cont, {records, false}}
        else
          {:halt, {records, true}}
        end
      end)

    %{
      "schema" => "rmxos_oracle.migration.d14.guest_execution.v1",
      "passed" => not hard_failed?,
      "transitional_shell_tools" => true,
      "external_tool_mode" => "source_tree_with_sha256_enforcement",
      "host_log_path" => Path.basename(host_log),
      "commands" => records
    }
  end

  defp dispatch_commands(true, _archive, script),
    do: [
      {"build Phase 0.7 libdispatch archive",
       script.("scripts/dispatch/compile-libdispatch-build-lane.sh"), ["--strict"]}
    ]

  defp dispatch_commands(false, archive, script) do
    if File.exists?(archive) do
      []
    else
      [
        {"build Phase 0.7 libdispatch archive",
         script.("scripts/dispatch/compile-libdispatch-build-lane.sh"), ["--strict"]}
      ]
    end
  end

  defp run_command(command, env, host_log) do
    {label, cmd, args, extra_env} =
      case command do
        {label, cmd, args} -> {label, cmd, args, []}
        {label, cmd, args, extra_env} -> {label, cmd, args, extra_env}
      end

    command_env = command_env(env, extra_env)
    File.write!(host_log, "\n==> #{label}\n$ #{cmd} #{Enum.join(args, " ")}\n", [:append])

    {out, status} = System.cmd(cmd, args, env: command_env, stderr_to_stdout: true)
    File.write!(host_log, out, [:append])

    %{
      "label" => label,
      "cmd" => cmd,
      "args" => args,
      "exit_status" => status,
      "output_sha256" => sha256(out)
    }
  end

  defp command_env(env, extra_env) do
    base =
      env
      |> Map.take([
        "NXPLATFORM_WORKSPACE_ROOT",
        "NXPLATFORM_FREEBSD_SRC",
        "NXPLATFORM_KERNEL_OBJDIRPREFIX",
        "MAKEOBJDIRPREFIX",
        "NXPLATFORM_ARTIFACTS_DIR",
        "NXPLATFORM_PHASE1_LAUNCHD_HARNESS_WORKDIR",
        "NXPLATFORM_PHASE07_LIBDISPATCH_DIR",
        "NXPLATFORM_SERIAL_LOG",
        "NXPLATFORM_PHASE08_LAUNCHD_DISPATCH_LAUNCHCTL_PLIST_SERIAL_LOG",
        "NXPLATFORM_KERNEL_CONF",
        "NXPLATFORM_EXPECT_KERNEL",
        "NXPLATFORM_VM_NAME",
        "NXPLATFORM_VM_IMAGE",
        "NXPLATFORM_PHASE1_LAUNCHD_HARNESS_TIMEOUT",
        "NXPLATFORM_PHASE08_LAUNCHD_DISPATCH_REBUILD"
      ])
      |> Enum.map(fn {key, value} -> {key, value} end)

    base ++ extra_env
  end

  defp read_serial_log(%{"resolved" => %{"NXPLATFORM_SERIAL_LOG" => serial_log}}) do
    if File.regular?(serial_log), do: File.read!(serial_log)
  end

  defp read_serial_log(_env_result), do: nil

  defp invariant_checks(log) do
    pid_markers = [
      "phase08_dispatch_launchctl_plist_client_pid",
      "PHASE08_D14_MANAGEMENT_CLIENT_PID",
      "PHASE08_D14_EXPECTED_MANAGEMENT_CLIENT_PID",
      "PHASE08_D14_CALLER_AUDIT_PID"
    ]

    pid_values = Enum.map(pid_markers, &{&1, marker_int(log, &1)})
    pid_values_present? = Enum.all?(pid_values, fn {_marker, value} -> is_integer(value) end)
    unique_pid_values = pid_values |> Enum.map(&elem(&1, 1)) |> Enum.uniq()

    [
      %{
        "kind" => "invariant",
        "id" => "d14_pid_markers_equal",
        "passed" => pid_values_present? and length(unique_pid_values) == 1,
        "values" => Map.new(pid_values),
        "reason" => "D14 launchctl client PID markers must agree"
      },
      int_equals_check(log, "PHASE08_D14_DONOR_JOB_PID", 0),
      int_equals_check(log, "PHASE08_D14_DONOR_JOB_ACTIVE", 0)
    ]
  end

  defp int_equals_check(log, marker, expected) do
    value = marker_int(log, marker)

    %{
      "kind" => "invariant",
      "id" => "#{marker}_equals_#{expected}",
      "marker" => marker,
      "expected" => expected,
      "actual" => value,
      "passed" => value == expected
    }
  end

  defp marker_int(log, marker) do
    case Regex.run(~r/#{Regex.escape(marker)}=(-?[0-9]+)/, log) do
      [_, value] -> String.to_integer(value)
      _ -> nil
    end
  end

  defp order_check(log, markers) do
    {last, passed, missing_or_out_of_order} =
      Enum.reduce(markers, {-1, true, []}, fn marker, {last, passed, missing} ->
        case :binary.match(log, marker) do
          {idx, _len} when idx > last -> {idx, passed, missing}
          {idx, _len} -> {idx, false, missing ++ [marker]}
          :nomatch -> {last, false, missing ++ [marker]}
        end
      end)

    %{
      "kind" => "ordering",
      "id" => "d14_required_order_tail",
      "passed" => passed,
      "last_index" => last,
      "missing_or_out_of_order" => missing_or_out_of_order
    }
  end

  defp not_run_report(schema_suffix) do
    %{
      "schema" => "rmxos_oracle.migration.d14.#{schema_suffix}.v1",
      "passed" => false,
      "skipped" => true,
      "reason" => "oracle serial log was not available"
    }
  end

  defp file_identity(path) when is_binary(path) do
    if File.regular?(path) do
      stat = File.stat!(path)
      %{"path" => path, "sha256" => sha256_file(path), "size" => stat.size}
    else
      %{"path" => path, "sha256" => nil, "missing_reason" => "file not found"}
    end
  end

  defp file_identity(_path),
    do: %{"path" => nil, "sha256" => nil, "missing_reason" => "path unavailable"}

  defp hash_present?(%{"sha256" => sha}) when is_binary(sha) and sha != "", do: true
  defp hash_present?(_identity), do: false

  defp legacy_contract_source_ref do
    %{
      "tag" => @default_legacy_ref,
      "commit" => @expected_legacy_commit,
      "path" => @legacy_contract_path,
      "sha256" => @legacy_contract_sha256
    }
  end

  defp resolve_legacy_commit!(legacy_repo, legacy_ref) do
    commit = git!(legacy_repo, ["rev-parse", "--short", "#{legacy_ref}^{commit}"])

    unless commit == @expected_legacy_commit do
      raise "legacy ref #{legacy_ref}^{commit} resolved to #{commit}, expected #{@expected_legacy_commit}"
    end

    commit
  end

  defp hash_legacy_files!(legacy_repo, legacy_commit) do
    Enum.map(@legacy_files, fn path ->
      bytes = git_bytes!(legacy_repo, ["show", "#{legacy_commit}:#{path}"])
      entry = hash_entry(path, bytes)

      if path == @legacy_contract_path and entry["sha256"] != @legacy_contract_sha256 do
        raise "legacy D14 contract hash mismatch: #{entry["sha256"]}"
      end

      if path == @fixture_path and entry["sha256"] != @fixture_sha256 do
        raise "D14 fixture hash mismatch: #{entry["sha256"]}"
      end

      entry
    end)
  end

  defp hash_oracle_files!(oracle_repo) do
    Enum.map(@oracle_files, fn path ->
      bytes = File.read!(Path.join(oracle_repo, path))
      hash_entry(path, bytes)
    end)
  end

  defp hash_entry(path, bytes) do
    %{"path" => path, "sha256" => sha256(bytes), "size" => byte_size(bytes)}
  end

  defp evidence_files(evidence_dir) do
    evidence_dir
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, evidence_dir))
    |> Kernel.++(["parity.json"])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp default_evidence_dir(out_root) do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_iso8601(:basic)
      |> String.replace("Z", "Z")

    Path.join(out_root, "#{timestamp}-phase08-d14-launchctl-plist")
  end

  defp git!(repo, args) do
    repo
    |> git_bytes!(args)
    |> String.trim()
  end

  defp git_bytes!(repo, args) do
    case System.cmd("git", ["-C", repo | args], stderr_to_stdout: true) do
      {out, 0} ->
        out

      {out, status} ->
        raise "git -C #{repo} #{Enum.join(args, " ")} failed with #{status}: #{out}"
    end
  end

  defp sha256(bytes), do: bytes |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  defp sha256_file(path) do
    path
    |> File.stream!(1024 * 1024, [])
    |> Enum.reduce(:crypto.hash_init(:sha256), fn chunk, context ->
      :crypto.hash_update(context, chunk)
    end)
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end
end
