# Postmortem: Parallel N2 MACH_SEND Preflight Staging Collision

Date: 2026-06-12
Mode: explorer
Repository: Oracle

## Summary

During preparation for the N2 MACH_SEND replacement smoke, Oracle incorrectly
launched four real staging preflights in parallel. Those preflights all default
to the same VM image and staged guest root:

- `/Users/me/wip-mach/vm/runs/nxplatform-dev.img`
- `/Users/me/wip-mach/vm/runs/nxplatform-dev.root`

The preflights were not independent host checks. Each can attach the image,
mount the staged root, install files, and unmount/detach during cleanup. Running
them concurrently caused a shared staging collision.

This was an Oracle orchestration error, not a guest runtime failure, kernel
failure, or source product failure.

## Scope

Governing activation:

- `docs/phase-0.95a-notifyd-n2-dispatch-dead-name-decode-fix-activation-record.md`
  at `602daef311f55179842415055131bbc7fd839f28`

Requested runtime source pin:

- `170db64c6643c3d8cc9ddaca5dcdcc20954537d7`

Run directory created before the stop:

- `priv/runs/notifyd-n2-mach-send/20260612T105058Z-dead-name-decode-fix-sweep-enable-verify/`

## Impact

- No guest execution started.
- No `serial.log` was produced.
- No `run-guest.rc` was produced.
- No candidate `NOTIFYD_N2_*` runtime markers were emitted.
- The Attempt A guest budget was not consumed.
- Attempt B was not reached.
- Oracle and source git-tracked files were not modified by the failed staging
  collision.
- The shared staged root was left as an empty mountpoint directory after cleanup:
  `/Users/me/wip-mach/vm/runs/nxplatform-dev.root`.

## What Happened

Oracle ran the required source boundary and stable15 environment checks, then
started the four preflight scripts concurrently:

- `preflight-phase095a-notifyd-n2-mach-send.sh`
- `preflight-phase095a-notifyd-n2-mach-raw-notify.sh`
- `preflight-phase095a-notifyd-n2-mach-direct-kevent.sh`
- `preflight-phase095a-notifyd-n2-dispatch-notify-trace.sh`

The source scripts default to the shared VM image path
`/Users/me/wip-mach/vm/runs/nxplatform-dev.img`. The shared staging helper
derives the guest root from `NXPLATFORM_VM_NAME`, whose default is
`nxplatform-dev`.

The collision became visible in the captured logs:

- `raw-preflight.log` recorded:
  `mdconfig: ioctl(/dev/mdctl): Device busy`
- `mach-send-preflight.log` recorded:
  `mkdir: /Users/me/wip-mach/vm/runs/nxplatform-dev.root/boot/MACHDEBUGDEBUG: No such file or directory`

The failure pattern is consistent with one preflight attaching or cleaning up
the shared image/root while another preflight still expected the mounted guest
filesystem to be present.

## Root Cause

Oracle treated the four preflights as parallelizable read-only checks. That was
wrong. They are real staging preflights and mutate shared host staging state.

The root cause was unsafe parallel execution of scripts that share:

- one VM image,
- one staged root path,
- one mount lifecycle,
- and one `mdconfig` attach/detach surface.

## Attempt Accounting

This incident does not consume a guest attempt.

Reason:

- There was no guest execution.
- There was no `run-guest.rc`.
- There was no `serial.log`.
- There were no candidate runtime markers.

Under the Oracle attempt accounting rule, setup failure before guest execution
and before candidate runtime markers is not consumed runtime evidence.

## Guardrails Confirmed

- No guest run occurred.
- No N2 concurrency ran.
- No marker authority was authored.
- No Phase 0.85 authority was authored.
- No certification or artifact promotion occurred.
- No parity tag movement occurred.
- No source edits were made.
- Oracle worktree remained clean after the investigation.

## Corrective Actions

Immediate operating rule:

- Do not run VM-image or staged-root preflights in parallel unless each one is
  explicitly configured with an isolated `NXPLATFORM_VM_IMAGE`,
  `NXPLATFORM_VM_NAME`, and `NXPLATFORM_GUEST_ROOT`.

Gatekeeper activation discipline:

- Treat preflights that call staging helpers as stateful operations.
- Run shared-image preflights sequentially.
- If a preflight path needs parallel execution, require source-owned isolation
  of image/root names before parallelizing.

Future hardening candidate:

- Add a source-side or Oracle-side guard that detects concurrent use of the
  default `nxplatform-dev` staging image/root and fails before mutating the
  mount state.

## Disposition

Disposition: stopped before guest execution.

Classification: Oracle operator error, parallel preflight staging collision.

Next action requires Conductor/Maestro direction. The previous activation
should not be resumed from this partial preflight state without an explicit
decision on whether to rerun the required preflights sequentially or add an
isolation guard first.
