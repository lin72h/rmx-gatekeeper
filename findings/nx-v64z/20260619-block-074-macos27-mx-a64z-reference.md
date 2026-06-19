# block-074 macOS 27 mx-a64z reference

Date: 2026-06-19

Lane: `explorer-mx-a64z`

Mode: macOS 27 ground-truth reference for parity cataloging

## Scope

This note records stock macOS 27 beta behavior from the native Apple Silicon
runner. It is a semantic oracle reference only. It does not claim ABI, layout,
raw port-name, pointer, timing, or XNU implementation equivalence with rmxOS.

No private entitlement, SIP change, privileged helper, private Apple header, or
XNU source-derived assumption was used.

## Sync

```text
git pull --ff-only
fast-forwarded main to 90346f4
```

## Environment

```text
hostname: mm4.local
agent: mx-a64z
ProductName: macOS
ProductVersion: 27.0
BuildVersion: 26A5353q
uname: Darwin mm4.local 27.0.0 Darwin Kernel Version 27.0.0: Wed May 27 02:11:37 PDT 2026; root:xnu-13361.0.0.501.1~2/RELEASE_ARM64_T8132 arm64
kern.osrelease: 27.0.0
kern.version: Darwin Kernel Version 27.0.0: Wed May 27 02:11:37 PDT 2026; root:xnu-13361.0.0.501.1~2/RELEASE_ARM64_T8132
hw.machine: arm64
hw.optional.arm64: 1
cpu: Apple M4
rosetta: native
sip: enabled
sandboxed: false
run_as_root: false
ad_hoc_signed: true
hardened_runtime: false
sdk_path: /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
sdk_version: 27.0
xcode_select_path: /Applications/Xcode-beta.app/Contents/Developer
compiler: Apple clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git 38c9bd4e92f23a7cbf1126f10b688eed60ec48d6)
```

Environment JSON:

```text
macos-validation/results/mx-a64z/20260619-27.0-27.0.0/environment.json
```

## Commands

```sh
git pull --ff-only
cd macos-validation
make
make run AGENT=mx-a64z
make validate-json
```

Build note: Xcode 27 beta SDK reports existing `mach_port_destroy()`
deprecation warnings. All probes built, signed, ran, and emitted valid JSON.

## Result Directory

```text
macos-validation/results/mx-a64z/20260619-27.0-27.0.0
```

Harness summary:

```text
Summary: 12 probes, 12 pass, 0 fail, 0 skip
Validated: 39 files, 39 pass, 0 fail
```

## Classification Summary

All 12 macOS 27 `mx-a64z` vectors are classified as `exact_contract`.

| Probe | Status | Classification | macOS 27 reference |
| --- | --- | --- | --- |
| `foundation/smoke` | pass | exact-contract | basic receive-right lifecycle succeeds; cleanup baseline |
| `foundation/port_names` | pass | exact-contract | allocation adds one name; destroy returns to baseline |
| `foundation/port_type` | pass | exact-contract | receive/send-receive/port-set/task-self types match expected public observations |
| `foundation/port_get_refs` | pass | exact-contract | receive refs and send urefs change predictably; cleanup baseline |
| `m1/header_copy_send_accounting` | pass | exact-contract | header `COPY_SEND` preserves send urefs at send and receive |
| `m1/header_move_send_accounting` | pass | exact-contract | header `MOVE_SEND` consumes sender send urefs at send return |
| `m2/descriptor_copy_send` | pass | exact-contract | descriptor `COPY_SEND` preserves sender send right and delivers usable send right |
| `m2/descriptor_move_send` | pass | exact-contract | descriptor `MOVE_SEND` consumes sender send right and delivers usable send right |
| `m2/send_once_descriptor` | pass | exact-contract | descriptor `MOVE_SEND_ONCE` delivers one usable send-once right |
| `m2/invalid_descriptor_disposition` | pass | exact-contract | invalid disposition `0xff` returns `MACH_SEND_INVALID_RIGHT`, no delivery, no right consumption |
| `m2/dead_name_descriptor_right` | pass | exact-contract | dead-name `MOVE_SEND` source is accepted, consumed, and delivered; nonexistent source is rejected |
| `m2/double_move_send_descriptor` | pass | exact-contract | duplicate `MOVE_SEND` returns `MACH_SEND_INVALID_RIGHT`, no delivery, sender send right fully consumed |

## Per-Probe macOS 27 Reference

### foundation/smoke

- Result: `pass`
- Classification: `exact_contract`
- Cleanup: returned to baseline

### foundation/port_names

- Result: `pass`
- Classification: `exact_contract`
- Names before: `11`
- Names after allocate: `12`
- Names after destroy: `11`
- Cleanup delta: `0`

### foundation/port_type

- Result: `pass`
- Classification: `exact_contract`
- Receive type: `MACH_PORT_TYPE_RECEIVE`
- Send+receive type: `MACH_PORT_TYPE_SEND_RECEIVE`
- Port set type: `MACH_PORT_TYPE_PORT_SET`
- `mach_task_self()` type observed: `MACH_PORT_TYPE_SEND`
- Cleanup delta: `0`

### foundation/port_get_refs

- Result: `pass`
- Classification: `exact_contract`
- Receive refs initial/final: `1 -> 1`
- Send refs: `0 -> 1 -> 2 -> 1 -> 0`
- Cleanup delta: `0`

### m1/header_copy_send_accounting

- Result: `pass`
- Classification: `exact_contract`
- Sent `msgh_bits`: `0x13`
- Send urefs: `1 -> 1 -> 1`
- Port type remains `MACH_PORT_TYPE_SEND_RECEIVE`
- Receive returns message with local disposition `MACH_MSG_TYPE_MOVE_SEND`
- Cleanup delta: `0`

### m1/header_move_send_accounting

- Result: `pass`
- Classification: `exact_contract`
- Sent `msgh_bits`: `0x11`
- Send urefs: `1 -> 0 -> 0`
- Port type changes `MACH_PORT_TYPE_SEND_RECEIVE -> MACH_PORT_TYPE_RECEIVE`
- Receive returns message with local disposition `MACH_MSG_TYPE_MOVE_SEND`
- Cleanup delta: `0`

### m2/descriptor_copy_send

- Result: `pass`
- Classification: `exact_contract`
- Sent `msgh_bits`: `0x80000013`
- Child cargo send urefs: `1 -> 1 -> 1`
- Child cargo type remains `MACH_PORT_TYPE_SEND_RECEIVE`
- Parent delivered descriptor type: `MACH_PORT_TYPE_SEND`
- Parent delivered send refs: `1`
- Delivered right usable: `true`
- Parent cleanup delta: `0`
- Child cleanup delta: `0`

### m2/descriptor_move_send

- Result: `pass`
- Classification: `exact_contract`
- Sent `msgh_bits`: `0x80000013`
- Child cargo send urefs: `1 -> 0 -> 0`
- Child cargo type changes `MACH_PORT_TYPE_SEND_RECEIVE -> MACH_PORT_TYPE_RECEIVE`
- Parent delivered descriptor type: `MACH_PORT_TYPE_SEND`
- Parent delivered send refs: `1`
- Delivered right usable: `true`
- One parent deallocate is sufficient: `true`
- Parent cleanup delta: `0`
- Child cleanup delta: `0`

### m2/send_once_descriptor

- Result: `pass`
- Classification: `exact_contract`
- Send-once creation API: `mach_port_extract_right(MACH_MSG_TYPE_MAKE_SEND_ONCE)`
- Child send-once refs before send: `1`
- Child send-once right consumed after send: `true`
- Parent delivered type: `MACH_PORT_TYPE_SEND_ONCE`
- Parent delivered send-once refs: `1`
- First use succeeds; second use returns `MACH_SEND_INVALID_DEST`
- Child first receive returns `MACH_MSG_SUCCESS`
- Child second receive returns `MACH_RCV_TIMED_OUT`
- Parent cleanup delta: `0`
- Child cleanup delta: `0`

### m2/invalid_descriptor_disposition

- Result: `pass`
- Classification: `exact_contract`
- Invalid descriptor disposition: `0xff`
- `mach_msg(SEND)` returns `MACH_SEND_INVALID_RIGHT`
- Receive after send returns `MACH_RCV_TIMED_OUT`
- Message delivered: `false`
- Service send refs unchanged: `true`
- Cargo send refs unchanged: `true`
- Cargo type unchanged: `true`
- Cleanup delta: `0`

### m2/dead_name_descriptor_right

- Result: `pass`
- Classification: `exact_contract`
- Dead-name source:
  - source before: `MACH_PORT_TYPE_DEAD_NAME`, refs `1`
  - send returns `MACH_MSG_SUCCESS`
  - source after returns `KERN_INVALID_NAME`
  - receive returns `MACH_MSG_SUCCESS`
  - message delivered: `true`
  - received descriptor count: `1`
  - received descriptor disposition: `MACH_MSG_TYPE_MOVE_SEND_OR_PORT_SEND`
  - cleanup delta: `0`
- Nonexistent source:
  - source before: `KERN_INVALID_NAME`
  - send returns `MACH_SEND_INVALID_RIGHT`
  - receive after send returns `MACH_RCV_TIMED_OUT`
  - message delivered: `false`
  - cleanup delta: `0`

### m2/double_move_send_descriptor

- Result: `pass`
- Classification: `exact_contract`
- Two descriptors name the same send right with `MACH_MSG_TYPE_MOVE_SEND`
- `mach_msg(SEND)` returns `MACH_SEND_INVALID_RIGHT`
- Receive after send returns `MACH_RCV_TIMED_OUT`
- Message delivered: `false`
- Cargo send refs: `1 -> 0 -> 0`
- Cargo type: `MACH_PORT_TYPE_SEND_RECEIVE -> MACH_PORT_TYPE_RECEIVE`
- Sender consumption class: `fully_consumed`
- Cleanup delta: `0`

## macOS 27 Version-Sensitive Flags

None from this run.

No probe failed to build or run on macOS 27 beta `26A5353q`. No result was
classified as `version-sensitive`, `privilege-sensitive`, `not-observable`, or
`probe-failure`.

## Notes For rx Comparison

This is a reference capture only. It does not judge rmxOS behavior and does not
promote any mismatch into implementation work. Compare semantic fields first
and ignore raw Mach port names, pointer values, struct padding, raw buffer
layout, and absolute timing.
