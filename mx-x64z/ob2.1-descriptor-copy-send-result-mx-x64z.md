# mx-x64z OB2.1 Descriptor COPY_SEND Result

Date: 2026-05-13

Agent: `mx-x64z`

Probe: `m2/descriptor_copy_send.c`

Test ID: `macos_m2_descriptor_copy_send`

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
macos-validation/results/mx-x64z/20260513-26.4-25.4.0/m2_descriptor_copy_send.json
```

Empty stderr logs were not force-added.

## Harness Summary

```text
Summary: 7 probes, 7 pass, 0 fail, 0 skip
Validated: 17 files, 17 pass, 0 fail
```

## Descriptor COPY_SEND Result

Status: `pass`

Semantic class: `exact_contract`

Key observations:

- transport setup: bootstrap special-port inheritance plus status pipe
- child cargo type before send: `MACH_PORT_TYPE_SEND_RECEIVE`
- child cargo type after descriptor send: `MACH_PORT_TYPE_SEND_RECEIVE`
- child cargo type after parent verification: `MACH_PORT_TYPE_SEND_RECEIVE`
- child cargo send urefs before send: `1`
- child cargo send urefs after descriptor send: `1`
- child cargo send urefs after parent verification: `1`
- descriptor `COPY_SEND` preserved child cargo send urefs: `true`
- sent descriptor message bits: `0x80000013`
- received descriptor message bits: `0x80001100`
- received descriptor count: `1`
- delivered descriptor disposition raw hex: `0x11`
- delivered descriptor disposition: `MACH_MSG_TYPE_MOVE_SEND_OR_PORT_SEND`
- parent delivered port type: `MACH_PORT_TYPE_SEND`
- parent delivered send refs: `1`
- delivered right usable: `true`
- parent verification send returned `MACH_MSG_SUCCESS`
- child verification receive returned `MACH_MSG_SUCCESS`
- child cleanup delta: `0`
- parent cleanup delta: `0`
- cleanup returned to baseline: `true`
- `entry_refs_before` and `entry_refs_after` remain `null`

## Finding

On native Intel macOS 26.4 / Darwin 25.4.0, descriptor
`MACH_MSG_TYPE_COPY_SEND` preserves the sender child's observable cargo send
urefs and delivers a usable send right to the parent.

No OB2.1 stop condition occurred on `mx-x64z`.

No OB2.2 probe was started.
