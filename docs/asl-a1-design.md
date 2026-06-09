STATUS: Draft / Awaiting Review

# ASL A1 Design

This document designs the first ASL runtime probe. It is design-only: no ASL
implementation, guest run, marker manifest entry, launchctl migration,
certification claim, source mutation, or evidence artifact is created by this
document.

A1 builds directly on the accepted A0 classification:

- Oracle A0 record:
  `e80dbb37ebe752353c75438718f5ac3e4d188e9c`
- A0 document: `docs/asl-a0-build-classification.md`
- ASL donor tree:
  `/Users/me/wip-mach/nx/NextBSD`
- ASL donor commit:
  `8be0f2507b69906d068bed31ffc58cdfafadaef3`
- ASL MIG contract:
  `lib/libasl/asl_ipc.defs`, subsystem `asl_ipc 114`
- First target routine:
  `_asl_server_message`, message id `118`, MIG `simpleroutine`

## Runtime Claim

Primary A1 claim:

```text
One _asl_server_message OOL payload is sent to a receiver using donor ASL MIG
demux/decode. The OOL bytes arrive intact, donor ASL decode accepts the message,
and the decoded key/value payload reaches the project-owned process_message
stub.
```

Audit identity sub-claim:

- Include only if A1 proves `audit_token_t` UID/GID/PID delivery and match
  against the sender identity observed by the probe.
- If the audit token is absent, zero-only, malformed, or not matchable, A1 must
  explicitly defer audit identity and claim only OOL transport/decode.
- If `task_name_for_pid` remains stubbed or unavailable, do not claim ASL
  session tracking.

Explicit non-claims:

- No launchd service/check-in/MachServices claim.
- No ASL storage, query, match, prune, aux-link, direct-watch, or retrieval
  claim.
- No libc `syslog(3)`, BSD socket input, UDP syslog, remote syslog, or
  aslmanager claim.
- No XPC, broad libnotify, full BSM/audit policy, or session lifecycle claim.
- No certification claim.

## Harness Shape

A1 must be a guest integration probe. The probe may use transitional build/stage
tools, but the behavioral proof must be produced by a standalone ASL probe
binary and oracle-owned validation. Harness-only markers cannot prove ASL
behavior.

### Client Build Shape

The client side should be a project-owned probe path that sends exactly one
`_asl_server_message` request.

Preferred shape:

- Generate `asl_ipcUser.c` and `asl_ipc.h` from donor `asl_ipc.defs` using the
  staged MIG tool proven by A0.
- Compile the generated client stub into the probe.
- Build a minimal ASL string payload with deterministic key/value content. The
  payload should match the donor `ASL_STRING_MIG` string grammar accepted by
  `asl_msg_from_string`.
- Allocate the payload as OOL memory and call generated
  `_asl_server_message(server_port, payload, payload_length)`.

Acceptable fallback if generated user stub integration is blocked:

- A project-owned client may construct an equivalent request matching the
  generated request ABI, but the evidence must record why the generated user
  stub was not used.
- This fallback still must target generated/donor server demux on the receive
  side. It cannot downgrade the receiver to a toy parser.

The client should record:

- send return code,
- OOL payload length and SHA256,
- expected key/value pairs,
- sender PID/UID/GID used for optional audit comparison,
- whether generated user stub or equivalent request construction was used.

### Server Build Shape

The server side must invoke donor ASL MIG demux/decode:

- Generate `asl_ipcServer.c`, `asl_ipcServer.h`, and the server-visible
  `asl_ipc.h` from donor `asl_ipc.defs`.
- Compile generated `asl_ipcServer.c`.
- Compile a narrow donor ASL decode object set sufficient for
  `__asl_server_message`:
  - donor `usr.sbin/asl/dbserver.c`, or a narrowed extracted donor translation
    unit for `__asl_server_message` if required to avoid unrelated daemon
    dependencies;
  - donor ASL message parser/codec objects needed by
    `asl_msg_from_string`, `asl_msg_set_key_val`, and message release paths,
    expected to include selected files from `lib/libasl` such as
    `asl_msg.c`, `asl_string.c`, `asl_object.c`, `asl_core.c`,
    `asl_common.c`, and supporting headers;
  - generated ASL server stubs.
- Link project-owned stubs for daemon hooks instead of linking the full ASL
  daemon.

If compiling full `dbserver.c` pulls too much daemon surface, the first
implementation may extract only donor `__asl_server_message` into a pinned
donor reference payload. That extraction must preserve the donor logic for:

- null-message handling,
- null-termination check,
- OOL `vm_deallocate`,
- `asl_msg_from_string`,
- audit token UID/GID/PID decode,
- UID/GID/PID stamping when audit identity is enabled,
- final `process_message(msg, SOURCE_ASL_MESSAGE)` handoff.

### Receive Right And Client Handoff

The server harness should create one receive right with public Mach APIs:

1. allocate a receive right;
2. insert or make one send right for the client;
3. hand the send right to the client process by the selected harness mechanism;
4. keep ownership/provenance of both names in the evidence.

The first A1 design does not require launchd/bootstrap name lookup. Direct
parent/child handoff is preferred because it isolates ASL transport/decode from
launchd service handoff.

### Receive And Audit Trailer

The server receive loop must request an audit trailer:

```text
MACH_RCV_MSG
| MACH_RCV_TRAILER_ELEMENTS(MACH_RCV_TRAILER_AUDIT)
| MACH_RCV_TRAILER_TYPE(MACH_MSG_TRAILER_FORMAT_0)
```

The receive buffer must be large enough for the generated ASL request union plus
the maximum trailer size used by the target headers. Evidence must record:

- receive return code;
- received message id;
- received `msgh_bits`;
- whether the message is complex and has the expected OOL descriptor;
- trailer type/size;
- whether audit token bytes were present;
- raw or normalized audit UID/GID/PID if available.

### Generated Demux Invocation

After receiving the request, the server must call:

```text
asl_ipc_server(&request->head, &reply->head)
```

The generated server stub must dispatch message id `118` into donor
`__asl_server_message(...)`. The proof must include donor-decode markers from
inside or immediately around the donor path, not only harness markers before
and after `asl_ipc_server`.

The server must record:

- `asl_ipc_server` handled/not-handled result;
- generated request id;
- donor `__asl_server_message` entry marker;
- donor decode success/failure marker;
- stubbed `process_message` receipt marker;
- no-reply behavior for the simpleroutine path.

## Stub And Fence Plan

### `process_message` / Storage

A1 replaces storage with a project-owned `process_message` stub.

Stub behavior:

- require `source == SOURCE_ASL_MESSAGE`;
- record the decoded ASL message keys/values;
- record the original OOL payload SHA256 if available;
- set a terminal donor-consumed marker only after the decoded payload is
  recorded;
- release the ASL message using the donor-compatible release path.

The stub must not:

- open `asl_store` or `asl_memory` databases;
- write ASL files;
- trigger `aslmanager`;
- run output actions;
- make a storage/query/retrieval claim.

### `task_name_for_pid` / Session Tracking

Default A1 plan: defer session tracking.

Implementation options:

- compile/link a stub `task_name_for_pid` that returns failure and record
  `ASL_A1_SESSION_TRACKING=deferred`; or
- gate the donor code path so `register_session` is not called.

If A1 chooses to enable `task_name_for_pid`, it must become an explicit
sub-claim with its own markers and failure cases. Do not let a successful
transport/decode proof silently claim session tracking.

### `libnotify`

Default A1 plan: stub/fence notify.

Exact symbols to stub if the selected object set pulls them:

- `notify_register_plain`
- `notify_register_dispatch`
- `notify_register_file_descriptor`
- `notify_check`
- `notify_get_state`
- `notify_post`
- `notify_cancel`

Notify stubs must record that notify behavior is deferred. A1 must not claim
libnotify or notifyd semantics.

### Audit / BSM

A1 may use `audit_token_t` and `audit_token_to_au32` only.

Allowed:

- include BSM headers needed for `audit_token_t`;
- call or stub `audit_token_to_au32` only to decode UID/GID/PID from the
  received audit token.

Not allowed in A1:

- audit daemon behavior;
- audit policy;
- BSM event logging;
- broad `libauditd` / `libbsm` claims.

### Fenced Paths

The following paths are out of A1 and must be fenced out or left unlinked:

- XPC entitlement and aslmanager paths;
- `aslmanager` XPC server;
- `asl_trigger_aslmanager`;
- libc `syslog(3)`;
- BSD socket syslog input;
- UDP syslog input;
- remote syslog;
- direct watch registration/cancel;
- ASL query, match, prune, and aux-link routines.

## Marker And Evidence Strategy

A1 should introduce marker taxonomy in the implementation, but this design does
not add marker manifest entries.

Proposed producer categories:

- `client`: project-owned sender path;
- `asl_server`: project-owned receive/demux harness;
- `donor_decode`: donor ASL MIG server or donor `__asl_server_message` path;
- `harness`: staging, environment, and process orchestration.

Harness-only markers cannot prove ASL behavior. A1 pass criteria must include
`donor_decode` markers and the `process_message` stub's decoded payload record.

Suggested marker families:

- `ASL_A1_CLIENT_*`: client construction and send status;
- `ASL_A1_SERVER_*`: receive, trailer, descriptor, and demux status;
- `ASL_A1_DONOR_*`: donor `__asl_server_message` entry/decode/dealloc/handoff
  status;
- `ASL_A1_STUB_*`: process-message stub observations;
- `ASL_A1_AUDIT_*`: audit token presence and optional identity match;
- `ASL_A1_NEGATIVE_*`: falsifier results;
- `ASL_A1_DONE=1`: terminal marker emitted only after all required positive
  observations are recorded.

Serial truncation policy:

- Missing `ASL_A1_DONE=1` is fail-closed.
- Missing donor decode markers are fail-closed even if harness markers exist.
- A log ending after client send but before donor decode is indeterminate/fail.
- A log ending after donor decode but before terminal marker is
  indeterminate/fail.

Raw evidence should be ignored under:

```text
priv/runs/asl-a1/<timestamp>-asl-server-message-ool/
```

Expected evidence files for implementation:

- `parity.json` or `asl_a1_result.json`;
- `serial.log`;
- `host.log`;
- `env_resolved.json`;
- `source_hashes.json`;
- `mig_generation.json`;
- `build_artifacts.json`;
- `marker_comparison.json`;
- `hard_stop_scan.json`;
- `negative_controls.json`;
- `audit_identity.json` if audit identity is attempted.

Required provenance fields:

- Oracle commit;
- source roadmap repo commit;
- ASL donor path and commit;
- FreeBSD source path and commit;
- selected source profile and objdir;
- staged MIG tool path and hash if available;
- generated ASL MIG artifact hashes;
- client/server probe binary hashes;
- guest image hash;
- source object list and hashes;
- whether audit identity was included or deferred;
- whether session tracking was included or deferred.

## Falsifiers

A1 cannot be accepted from a green path alone. It must define and run negative
controls that prove the verifier and runtime can go red.

Required negative cases:

- Malformed ASL payload rejected:
  send an OOL payload that reaches donor demux but fails donor ASL parsing or
  policy validation; require no decoded-message pass marker.
- Missing or invalid OOL descriptor rejected:
  send a message id 118 request with absent, malformed, wrong-sized, or inline
  payload shape; require generated/donor server rejection or no donor decode
  pass marker.
- Missing terminal marker fails closed:
  mutate a passing serial log by removing `ASL_A1_DONE=1`; the oracle validator
  must fail with a terminal-marker-specific reason.
- Audit identity mismatch fails if audit identity is claimed:
  mutate observed UID/GID/PID expectation or run a controlled mismatch case;
  require failure. If audit identity is deferred, this falsifier is recorded as
  not applicable with reason.
- Toy receiver is not accepted:
  provide a synthetic log containing harness/client markers but no
  `donor_decode` markers and no generated `asl_ipc_server` dispatch evidence;
  validator must fail and report that donor ASL demux/decode was not proven.

Recommended additional falsifiers:

- OOL payload not null-terminated;
- wrong ASL message id;
- successful client send with no server receive;
- donor decode entry without `process_message` stub receipt;
- duplicated or conflicting decoded key/value marker.

## Build And Run Plan

### Expected Source/Object Set

Minimum expected source inputs:

- donor `lib/libasl/asl_ipc.defs`;
- generated `asl_ipcUser.c`;
- generated `asl_ipcServer.c`;
- generated headers `asl_ipc.h` and `asl_ipcServer.h`;
- selected donor ASL decode/message files from `lib/libasl`;
- donor `__asl_server_message` implementation from `usr.sbin/asl/dbserver.c`
  or a narrow extracted donor reference payload;
- project-owned client/server harness code;
- project-owned stubs for storage, notify, session, XPC/aslmanager, and other
  fenced paths.

The exact selected donor object set must be recorded before implementation is
accepted. If the object set changes after first review, rerun the A1 design or
implementation review for dependency drift.

### Generated MIG Artifacts

Expected generated artifacts:

- `asl_ipcUser.c`;
- `asl_ipcServer.c`;
- `asl_ipc.h`;
- `asl_ipcServer.h`;
- generated object files for client and server stubs.

Generation must use donor `asl_ipc.defs` pinned to
`8be0f2507b69906d068bed31ffc58cdfafadaef3` and the staged MIG toolchain
recorded by A0 or a later explicitly accepted toolchain record.

### Host Build Probes

Before any guest run, implementation should run host build probes that:

- regenerate ASL MIG artifacts;
- compile generated client and server stubs;
- compile the selected donor decode object set;
- link the standalone probe binary or binaries;
- emit source/object/hash provenance;
- fail if stubbed/fenced symbols drift beyond the approved list.

Host build probes do not certify ASL runtime behavior. They are only build and
dependency evidence.

### Guest Staging Shape

Later A1 implementation should stage only the artifacts needed for the ASL
transport/decode proof:

- standalone client/server probe binary or a combined parent/child probe;
- generated ASL MIG artifacts only if needed for runtime provenance;
- no full `asld` service installation;
- no launchd service plist/check-in path;
- no socket syslog service;
- no aslmanager.

Guest execution should prefer a single binary that forks client/server or a
parent-controlled pair so the receive right handoff is explicit and independent
of launchd/bootstrap lookup.

### Hard-Stop Scan

A1 hard-stop scan categories:

- kernel panic;
- fatal trap;
- KASSERT;
- WITNESS / lock order reversal;
- `SIGSYS`, `Bad system call`, or `UNKNOWN FreeBSD SYSCALL`;
- Mach send/receive unexpected fatal return;
- OOL descriptor validation failure on the positive path;
- ASL donor decode failure on the positive path;
- missing required marker;
- missing terminal marker;
- audit identity mismatch when audit identity is claimed;
- source/profile/objdir mismatch;
- staged artifact hash mismatch;
- boot-input contamination if guest-run staging is used.

## Dependency Checks

D22/D23 launchctl authority:

- A1 has no dependency on D22/D23 launchctl marker/order migration.
- D22/D23 remain audited/deferred and do not block ASL transport/decode.
- If a future ASL gate consumes new launchctl D22/D23 markers, inherits
  D19/D20 through D22, or adds a multi-arm launchctl pattern, then D22/D23
  migration must be revisited before that future gate.

Phase 0.85 / A2 launchd handoff:

- A1 does not require launchd MachServices handoff.
- A1 uses direct receive-right setup and client handoff.
- A2 is triggered if the selected ASL workflow needs any of:
  - launchd `com.apple.system.logger` MachServices advertisement;
  - `asld` launchd check-in;
  - client `bootstrap_look_up2` service discovery;
  - launchd-managed socket resource handoff;
  - full product service startup.

Other dependency triggers:

- `libnotify` becomes a separate narrow prerequisite only if selected A1 donor
  code cannot be stubbed/fenced without changing the `_asl_server_message`
  behavior under test.
- XPC/aslmanager becomes later work only if storage/rotation/manager behavior
  is selected.
- Full audit/BSM becomes later work only if A1 or a follow-on claim needs more
  than `audit_token_t` UID/GID/PID decoding.

## A1 Acceptance Criteria For Future Implementation

A future A1 implementation is acceptable only if:

- generated ASL MIG artifacts are built from the pinned donor `asl_ipc.defs`;
- one positive guest run reaches donor `asl_ipc_server` and donor
  `__asl_server_message`;
- OOL bytes are proven intact at the donor decode/process-message boundary;
- audit identity is either proven with UID/GID/PID match or explicitly deferred;
- every required falsifier fails closed;
- evidence is written only under ignored `priv/runs/`;
- no launchd handoff, storage, query, syslog, socket, XPC, aslmanager,
  broad libnotify, session tracking, or certification claim is made unless
  explicitly added by parent-approved scope.

## Guardrails For This Design Step

- No guest run.
- No ASL implementation.
- No marker manifest entries.
- No D22/D23 launchctl migration.
- No source-side edits or deletion.
- No `certification/`.
- No `artifacts/`.
- No `oracle-parity-a30ef3f` movement.
