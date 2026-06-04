# Stable/15 Post-Activation Minor Rebase Runbook

Status: active workflow after stable/15 candidate activation.

This runbook covers routine stable/15 minor syncs after activation of candidate `f71260cf4c9e`. It does not authorize a new sync by itself, does not create a certification claim, and does not repeat the one-time candidate adoption ceremony.

## Current Baseline

Active default:

- `NXPLATFORM_BASE_PROFILE` unset resolves to `stable15-active`.
- active source: `/Users/me/wip-mach/freebsd-src-official-stable-15`
- active source commit at activation: `f71260cf4c9e`
- active objdir: `/Users/me/wip-mach/build/official-stable15-mach-obj`
- activation commit: `15b5bdd04255 stable15: activate candidate env default`
- activation completion record: `ec2e268fc4f6 stable15: record activation completion`

Compatibility profiles:

- `official-stable15-candidate` remains an alias/backcompat name for the same active source, commit, and objdir constants.
- `releng151-current` remains explicit rollback only.

Rollback baseline:

- rollback profile: `releng151-current`
- rollback source: `/Users/me/wip-mach/wip-gpt/freebsd-src-stable-15`
- rollback source HEAD, checked out-of-band before use: `d4876c3fd9af`
- rollback objdir: `/Users/me/wip-mach/build/releng151-mach-obj`

## Routine Sync Boundary

A routine stable/15 minor sync may:

- merge upstream/fork updates into `/Users/me/wip-mach/freebsd-src-official-stable-15`
- clean-build the kernel and `mach.ko`
- bind the new active source HEAD to kernel, `kernel.full`, and `mach.ko` hashes
- update the Oracle env pin/artifact tuple for `stable15-active`
- run the env-check matrix
- stage the guest locally
- run D14 by default
- run D17/D18 only when the touched-path manifest triggers, or D14 shows marker drift/hard-stop risk

A routine stable/15 minor sync must not:

- mutate `/Users/me/wip-mach/wip-gpt/freebsd-src-stable-15`
- move `oracle-parity-a30ef3f`
- delete source files
- rename source paths
- create `certification/`
- create repo-local `artifacts/`
- commit raw evidence from `priv/runs/`
- claim certification
- repeat candidate adoption unless parent explicitly requests a new adoption decision

## Workflow

### 1. Preflight

Record current state before the source sync:

```sh
git -C /Users/me/wip-mach/wip-gpt-oracle rev-parse --short=12 HEAD
git -C /Users/me/wip-mach/wip-gpt rev-parse --short=12 HEAD
git -C /Users/me/wip-mach/wip-gpt rev-parse --short=12 oracle-parity-a30ef3f^{commit}
git -C /Users/me/wip-mach/freebsd-src-official-stable-15 rev-parse --short=12 HEAD
git -C /Users/me/wip-mach/wip-gpt/freebsd-src-stable-15 rev-parse --short=12 HEAD
```

Required preflight invariants:

- `oracle-parity-a30ef3f^{commit}` remains `a30ef3f`.
- rollback source remains `d4876c3fd9af`.
- Oracle worktree is clean or parent explicitly accepts the local diff.
- candidate worktree is clean before merging.
- `certification/` and repo-local `artifacts/` do not exist.

### 2. Source Sync

Merge the approved upstream/fork update into the active stable/15 source tree:

```sh
git -C /Users/me/wip-mach/freebsd-src-official-stable-15 fetch <remote> <ref>
git -C /Users/me/wip-mach/freebsd-src-official-stable-15 merge --no-ff <approved-ref>
```

Record:

- old active source HEAD
- new active source HEAD
- upstream/fork ref
- merge strategy
- touched-path manifest
- whether touched paths intersect Mach IPC, libthr/workqueue, audit, launchd, libdispatch, or D14/D17/D18 surfaces

This is a minor sync lane. Do not use it for stable/16, major base replacement, source path rename, or rollback-tree mutation.

### 3. Clean Build

Use the active configured objdir:

```sh
export NXPLATFORM_FREEBSD_SRC=/Users/me/wip-mach/freebsd-src-official-stable-15
export NXPLATFORM_KERNEL_OBJDIRPREFIX=/Users/me/wip-mach/build/official-stable15-mach-obj
export MAKEOBJDIRPREFIX=/Users/me/wip-mach/build/official-stable15-mach-obj
export NXPLATFORM_KERNEL_CONF=MACHDEBUGDEBUG
```

Build artifacts cleanly enough to bind the source HEAD to:

- kernel path, size, SHA256
- `kernel.full` path, size, SHA256
- `mach.ko` path, size, SHA256

The accepted artifact tuple is the new active source HEAD plus those hashes. File hashes are run provenance, not certification evidence.

### 4. Oracle Env Pin Update

Update the Oracle env pin/artifact tuple in one focused commit:

- `stable15-active` expected source commit becomes the new active source HEAD.
- `official-stable15-candidate` remains an alias sharing the same constants.
- source path remains `/Users/me/wip-mach/freebsd-src-official-stable-15`.
- objdir remains `/Users/me/wip-mach/build/official-stable15-mach-obj`.
- `releng151-current` remains explicit rollback only.

Run:

```sh
mix compile --warnings-as-errors
mix test
mix format --check-formatted
mix oracle.stable15.env_matrix
```

The env matrix must pass before staging or guest execution. After a source sync, it is expected to fail until the env pin is updated to the new active source HEAD.

### 5. S3 Stage

S3 means the local stage step that refreshes the guest image with the accepted kernel/module/harness artifacts. It is not Amazon S3 or a file service.

Stage the guest locally using the active source and objdir. Do not use releng151 kernel or module artifacts.

Required staging env:

```sh
env \
  NXPLATFORM_WORKSPACE_ROOT=/Users/me/wip-mach \
  NXPLATFORM_FREEBSD_SRC=/Users/me/wip-mach/freebsd-src-official-stable-15 \
  NXPLATFORM_KERNEL_OBJDIRPREFIX=/Users/me/wip-mach/build/official-stable15-mach-obj \
  MAKEOBJDIRPREFIX=/Users/me/wip-mach/build/official-stable15-mach-obj \
  NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD=/Users/me/wip-mach/build/official-stable15-mach-obj \
  NXPLATFORM_ARTIFACTS_DIR=/Users/me/wip-mach/artifacts/nxplatform \
  NXPLATFORM_PHASE1_LAUNCHD_HARNESS_WORKDIR=/Users/me/wip-mach/build/phase1-launchd-harness-link \
  NXPLATFORM_PHASE07_LIBDISPATCH_DIR=/Users/me/wip-mach/build/phase07-libdispatch \
  NXPLATFORM_KERNEL_CONF=MACHDEBUGDEBUG \
  <stage command>
```

Record ignored raw evidence under:

```text
priv/runs/stable15-minor-rebase/<timestamp>-s3-<new-head>/
```

S3 evidence must include:

- active source path and HEAD
- active objdir
- kernel, `kernel.full`, and `mach.ko` hashes
- pre/post guest image hash
- staging command/logs
- explicit statement whether the guest image was reused, refreshed, or newly created

### 6. D14 Default Gate

Run D14 by default after S3:

```sh
env \
  NXPLATFORM_WORKSPACE_ROOT=/Users/me/wip-mach \
  NXPLATFORM_FREEBSD_SRC=/Users/me/wip-mach/freebsd-src-official-stable-15 \
  NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD=/Users/me/wip-mach/build/official-stable15-mach-obj \
  NXPLATFORM_ARTIFACTS_DIR=/Users/me/wip-mach/artifacts/nxplatform \
  NXPLATFORM_PHASE1_LAUNCHD_HARNESS_WORKDIR=/Users/me/wip-mach/build/phase1-launchd-harness-link \
  NXPLATFORM_PHASE07_LIBDISPATCH_DIR=/Users/me/wip-mach/build/phase07-libdispatch \
  NXPLATFORM_BASE_PROFILE=stable15-active \
  NXPLATFORM_KERNEL_CONF=MACHDEBUGDEBUG \
  mix oracle.migration.parity phase08.d14.launchctl_plist_inert_load
```

D14 guest execution must use guest-run stdin isolation. The stdin isolation policy applies to D14, D17, and D18.

D14 must pass:

- boot identity
- marker comparison
- hard-stop scan
- negative control

Hard stops include:

- panic
- WITNESS lock-order hard stop
- KASSERT
- fatal trap
- `nosys 468`
- `rc=140` / SIGSYS from syscall 468
- missing required markers
- staged artifact hash mismatch
- source profile / objdir mismatch

### 7. D17/D18 Conditional Gates

Run D17/D18 only when one of these is true:

- touched-path manifest intersects Mach IPC, libthr/workqueue, audit, launchd lifecycle, libdispatch, or D17/D18 surfaces
- D14 passes but marker drift suggests lifecycle/hard-stop risk
- parent explicitly requests D17/D18

Use guest-run stdin isolation:

```sh
scripts/bhyve/run-guest.sh < /dev/null
```

The run is acceptable only when:

- marker contract passes
- hard-stop scan is clean
- validate-only rc is `0`
- serial contains harness end `rc=0`

`run-guest.rc=1` is non-authoritative only under those conditions.

### 8. Curated Run Provenance

Create one curated run provenance record per minor sync after raw evidence is reviewed. Suggested committed path:

```text
docs/stable15-minor-rebase-<new-head>.json
docs/stable15-minor-rebase-<new-head>.md
```

Schema:

- `priv/schemas/stable15_minor_rebase_run_v1.schema.json`

The record must distinguish:

- routine run provenance
- certification claims
- adoption decisions

Routine run provenance is not a certification claim and does not repeat the adoption ceremony.

Record at minimum:

- old active source HEAD
- new active source HEAD
- Oracle commit containing the env pin update
- source policy/docs repo commit
- rollback source HEAD
- artifact tuple
- env matrix result
- S3 evidence path/result
- D14 evidence path/result
- D17/D18 evidence path/result or reason not required
- raw evidence root under ignored `priv/runs/`
- guardrail booleans

## Failure Policy

If the env matrix fails:

- do not stage a guest
- fix env pin/source/objdir mismatch first

If S3 fails:

- do not run D14
- classify as build/stage/artifact issue

If D14 fails:

- do not run D17/D18
- classify first hard stop before wider testing

If D17/D18 fail:

- preserve failed evidence
- distinguish runner/stdin setup from runtime behavior before changing source

## Guardrails

- No certification claim.
- No `certification/`.
- No repo-local `artifacts/`.
- No source deletion.
- No source path rename.
- No `oracle-parity-a30ef3f` movement.
- No rollback tree mutation.
- No raw `priv/runs/` evidence committed.
- No guest run for runbook/tooling changes.
