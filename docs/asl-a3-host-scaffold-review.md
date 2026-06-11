# ASL A3 Host-Scaffold Review

Status: Oracle review record for source-side ASL A3 host-scaffold planning.
This is not an implementation record and does not authorize a guest run.

Source context:

- source repo: `/Users/me/wip-mach/wip-gpt`
- source HEAD inspected: `6176ae7bc961053908a31a68d6b8eee155259d03`
- source authorization: `docs/asl-a3-implementation-authorization.md`
- source design: `docs/asl-a3-submit-path-design.md`
- Oracle notifyd N1 authority: `2cb5d624031df21740099e63a27e8f2e8dc8522f`

## Decision

ASL A3 remains the correct next ASL lane after A1, A2, and notifyd N1, but
the source host scaffold is not review-ready until it handles three donor
reality blockers:

1. the default `asl_out_message()` path reaches the store branch;
2. `process_message()` and `asl_out_message()` are asynchronous in two stages;
3. notifyd staging mode must be declared and treated as supporting evidence.

No A3 guest attempt should be requested until these are encoded in source
preflight output and Oracle can verify them host-only.

## Accepted Claim Shape

The A3 runtime claim should be:

> A donor libasl client submits one ASL message through `com.apple.system.logger`;
> the donor ASL MIG server path receives and decodes it; donor
> `process_message()` accepts it in the work-queue block; donor action fan-out
> reaches the selected fenced sink; and the submitted nonce is observed there.

A3 must not claim:

- ASL query/retrieval;
- persistent storage correctness;
- socket syslog, UDP syslog, XPC, CORT, or aslmanager behavior;
- generic Phase 0.85 launchd handoff authority;
- notifyd N2 concurrency;
- certification.

## Blockers

### F1: Store Branch Must Be Fenced

Donor `asl_out_message()` routes to the store by default when no output modules
are configured:

```text
action_asl_store_count == 0 -> _send_to_asl_store(msg)
```

An empty module list is therefore not a no-op. Link-level "no storage pull-in"
checks are insufficient if runtime still reaches the store call site.

Required source scaffold behavior:

- add a source-owned fence at `_send_to_asl_store`;
- emit an A3 marker when the fenced store sink is reached;
- fail preflight if the fence marker string is absent;
- add a host falsifier proving "store send reached unfenced" fails;
- record that storage is fenced and not claimed.

Preferred sink:

- the fenced `_send_to_asl_store` call site.

Reason:

- it is the donor default destination;
- it is reached only after `process_message()` verify succeeds;
- it is reached after donor action-queue fan-out;
- it avoids accepting a sink that fires on synchronous `process_message()`
  return.

Fallback sink, if source cannot fence `_send_to_asl_store` narrowly:

- post-verify sink inside the `process_message()` work-queue block;
- the `_send_to_asl_store` fence is still mandatory.

### F2: Acceptance Point Must Cross Both Async Boundaries

Donor `process_message()` queues the real work with `dispatch_async()` and
returns before verification and fan-out. Donor `asl_out_message()` then queues
work again onto `asl_action_queue`.

Required marker phases:

- synchronous `process_message()` entry;
- work-queue block entry;
- `aslmsg_verify` status;
- `asl_out_message()` fan-out entry;
- action-queue entry;
- selected sink reached.

Acceptance point:

- `aslmsg_verify == VERIFY_STATUS_OK` inside the `process_message()` work-queue
  block is necessary but not sufficient if the selected sink is store-fence
  based.
- final A3 acceptance should require the selected sink marker after the donor
  action queue has processed the message.

Required falsifiers:

- sink before verify-OK fails;
- verify not OK treated as success fails;
- duplicate sink observation fails;
- work-queue drop path masquerading as success fails.

### F3: Notifyd Staging Mode Must Be Declared

Donor client code tolerates notify registration failure. A3 can work with or
without notifyd staged, but the scaffold must declare which mode is selected.

Recommended mode:

- stage notifyd using the accepted N1 scaffold;
- treat notify-registration status as supporting evidence only;
- do not make notifyd registration success a pass criterion for the ASL submit
  claim.

Reason:

- this gives an early cross-service integration datapoint;
- it does not burn the A3 attempt if notifyd is unavailable;
- N1 remains indirect handoff evidence and must not be promoted into generic
  Phase 0.85 authority.

## Required Source Preflight Additions

Before Oracle should accept an A3 host scaffold, source preflight must report
zero-status lines or explicit pass/fail records for:

- `ASL_DISABLE` absent from the A3 client environment;
- `_send_to_asl_store` fence present;
- store-fence marker string present;
- store-fence unfenced falsifier passes;
- selected sink placement recorded;
- acceptance point recorded as work-queue verify plus selected sink;
- notifyd staging mode declared;
- if notifyd is staged, N1 scaffold staging proof present;
- `task_name_for_pid` / `register_session` fence present;
- narrow `asl_action_queue` init present with no `asl.conf` parsing;
- OSAtomic symbols resolved;
- static no-pull-in check over excluded symbol families.

Excluded symbol families for the no-pull-in check should include:

- `asl_store_*`;
- `asl_memory_*`;
- `__asl_server_query*`;
- `__asl_server_fetch*`;
- `__asl_server_prune*`;
- `__asl_server_create_aux_link`;
- `__asl_server_register_direct_watch`;
- UDP, BSD socket, klog, remote input paths;
- `aslmanager` trigger strings.

The check must record whether each symbol family is absent, linked-but-unreached,
or fenced. A silent link pass is not enough.

## Expected Marker Families

These are expectations for future source-owned `ASL_A3_` markers only. Oracle
must not author A3 marker authority before accepted A3 runtime evidence.

Expected families:

- handoff and fixture witnesses;
- donor ASL lookup;
- client submit/open/log/close status;
- ASL_DISABLE absent / NO_REMOTE unset attestation;
- transport send, OOL byte count, and OOL SHA;
- server receive message id, complex bit, descriptor count;
- donor decode NUL-check, `asl_msg_from_string`, and `vm_deallocate`;
- audit trailer to `au32` UID/GID/PID match;
- `task_name_for_pid` / `register_session` fence markers;
- synchronous `process_message()` entry;
- work-queue block entry;
- `aslmsg_verify` status;
- `asl_out_message()` fan-out entry;
- action-queue entry;
- fenced store sink with nonce match;
- cleanup and terminal markers;
- rc-normalization markers.

Producer expectations:

- `:donor` for donor decode, process, fan-out, and store-fence facts;
- `:kernel` only if audit trailer values are load-bearing;
- `:harness` for orchestration, fixtures, fences, and rc normalization;
- `:launchd` only if source emits actual launchd-produced check-in/lookup
  facts, not harness constants.

## Guest Amendment Requirements

Any later A3 guest-attempt amendment should require an A2/N1-grade evidence set:

- `boot_identity.json`;
- `hard_stop_scan.json`;
- `marker_validation.json`;
- `marker_coverage.json`;
- `negative_controls.json`;
- `post_run_revalidation.json`;
- source pin and scaffold pin;
- runtime artifact hashes where captured;
- explicit limitations for any uncaptured hashes;
- rc-normalization policy before the run.

No run should be accepted from serial text alone.

## Phase 0.85 Boundary

ASL A3 does not unblock generic Phase 0.85 executable authority by itself.

Reason:

- A3 can add another ASL-side handoff instance;
- notifyd N1 remains indirect for launchd/kernel facts;
- the missing direct notifyd-side facts belong to notifyd N2 or a later
  explicit handoff authority extraction.

Do not copy A2 or notifyd N1 marker contracts into A3 or Phase 0.85.

## Oracle Guardrails

- Oracle must not edit `/Users/me/wip-mach/wip-gpt`.
- Oracle may validate only committed source pins.
- Oracle must stop and report the smallest falsifiable source requirement when
  product, runtime, build, staging, source-test, or source-documentation behavior
  is missing.
- Oracle probes, stubs, fixtures, validators, and marker authorities must not
  substitute for rmxOS product implementation.
- No A3 marker authority before accepted A3 evidence.
- No guest run from this review record.
- No N2, MACH_SEND smoke, generic Phase 0.85 extraction, certification,
  artifacts, source deletion, or parity-tag movement.

## Next One-Hour Source Requirement

The smallest useful next source task is:

1. inspect `_send_to_asl_store` and `register_session`;
2. choose the A3 sink, preferably fenced `_send_to_asl_store`;
3. add source host-scaffold preflight records for F1/F2/F3 without guest
   execution;
4. return a committed source pin for Oracle host-only verification.

Oracle should not request A3 guest authorization until that source pin passes
host-only review.
