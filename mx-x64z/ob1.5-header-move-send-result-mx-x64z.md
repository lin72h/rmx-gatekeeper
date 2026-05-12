# mx-x64z OB1.5 Header MOVE_SEND Result

Date: 2026-05-13

Agent: `mx-x64z`

Probe: `m1/header_move_send_accounting.c`

Test ID: `macos_m1_header_move_send_accounting`

## Host

```text
hostname: rkl.local
uname -m: x86_64
sw_vers:
  ProductName: macOS
  ProductVersion: 26.4
  BuildVersion: 25E246
uname -r: 25.4.0
```

Native Intel macOS.

## Commands

```sh
git pull --ff-only
cd macos-validation
make clean all
make run AGENT=mx-x64z
make validate-json
```

## Result Directory

```text
/Users/linz/Local/wip-mach/mach-oracle/macos-validation/results/mx-x64z/20260513-26.4-25.4.0
```

Raw artifacts for commit:

```text
macos-validation/results/mx-x64z/20260513-26.4-25.4.0/environment.json
macos-validation/results/mx-x64z/20260513-26.4-25.4.0/m1_header_move_send_accounting.json
```

Empty stderr logs were not force-added.

## Harness Summary

```text
Summary: 6 probes, 6 pass, 0 fail, 0 skip
Validated: 15 files, 15 pass, 0 fail
```

## Header MOVE_SEND Result

Status: `pass`

Semantic class: `exact_contract`

Key observations:

- send urefs before `mach_msg(SEND)`: `1`
- send urefs immediately after successful `mach_msg(SEND)`: `0`
- send urefs after successful `mach_msg(RECEIVE)`: `0`
- sender send urefs were consumed at SEND return: `true`
- port type before send: `MACH_PORT_TYPE_SEND_RECEIVE`
- port type after send: `MACH_PORT_TYPE_RECEIVE`
- port type after receive: `MACH_PORT_TYPE_RECEIVE`
- sent `msgh_bits`: `0x11`
- received `msgh_bits`: `0x1100`
- received remote/local labels: `MACH_PORT_NULL` / `service_port`
- received remote/local dispositions: `0` / `MACH_MSG_TYPE_MOVE_SEND`
- no delivered send right is observable after receive, so usability was not
  attempted
- cleanup delta: `0`
- cleanup returned to baseline: `true`
- `entry_refs_before` and `entry_refs_after` remain `null`

## Finding

On native Intel macOS 26.4 / Darwin 25.4.0, header
`MACH_MSG_TYPE_MOVE_SEND` consumes the sender's observable send right at
`mach_msg(SEND)` return.

No OB1.5 stop condition occurred on `mx-x64z`.

No OB2 probe was started.
