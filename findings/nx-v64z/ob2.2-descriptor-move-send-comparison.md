# OB2.2 Descriptor MOVE_SEND Comparison Findings

Date: 2026-05-13

Oracle results:
- `mx-a64z`: macOS 26.5, Darwin 25.5.0, arm64 Apple M4
- `mx-x64z`: macOS 26.4, Darwin 25.4.0, x86_64 Intel i7-11700K

Probe: `m2/descriptor_move_send.c`
Test ID: `macos_m2_descriptor_move_send`

## Summary

OB2.2 passed on both native macOS runners. Descriptor
`MACH_MSG_TYPE_MOVE_SEND` consumes the child sender's observable cargo send
right at successful `mach_msg(SEND)` return, leaves the child cargo name as a
receive right, and delivers a usable send right to the parent receiver.

Cross-runner result:

| Runner | Status | Cargo Send Urefs | Cargo Type Sequence | Delivered Type | Delivered Send Refs | Delivered Usable | Dealloc Count | Cleanup |
| --- | --- | --- | --- | --- | ---: | --- | ---: | --- |
| `mx-a64z` | `pass` | `1 -> 0 -> 0` | `SEND_RECEIVE -> RECEIVE -> RECEIVE` | `MACH_PORT_TYPE_SEND` | 1 | true | 1 | baseline |
| `mx-x64z` | `pass` | `1 -> 0 -> 0` | `SEND_RECEIVE -> RECEIVE -> RECEIVE` | `MACH_PORT_TYPE_SEND` | 1 | true | 1 | baseline |

No OB2.2 stop condition occurred.

## macOS Contract

For a controlled cross-task message where the child sends a cargo send right to
the parent using a port descriptor with `MACH_MSG_TYPE_MOVE_SEND`, native macOS
behavior on both runners is:

- child descriptor send returns `MACH_MSG_SUCCESS`
- parent descriptor receive returns `MACH_MSG_SUCCESS`
- child cargo send urefs before descriptor send: `1`
- child cargo send urefs immediately after descriptor send: `0`
- child cargo send urefs after parent verification: `0`
- child cargo type before descriptor send: `MACH_PORT_TYPE_SEND_RECEIVE`
- child cargo type after descriptor send: `MACH_PORT_TYPE_RECEIVE`
- child cargo type after parent verification: `MACH_PORT_TYPE_RECEIVE`
- sent descriptor message bits: `0x80000013`
- received descriptor message bits: `0x80001100`
- received descriptor count: `1`
- delivered descriptor disposition raw hex: `0x11`
- delivered descriptor disposition label: `MACH_MSG_TYPE_MOVE_SEND_OR_PORT_SEND`
- parent delivered port type: `MACH_PORT_TYPE_SEND`
- parent delivered send refs: `1`
- parent can send a verification Mach message through the delivered right
- child receives that verification message successfully
- one parent `mach_port_deallocate()` of the delivered right succeeds
- parent cleanup returns to baseline
- child cleanup returns to its reported baseline
- `entry_refs_before` and `entry_refs_after` remain `null`

The probe uses the same public setup pattern as OB2.1: bootstrap special-port
inheritance publishes the parent service port to the child, and a Unix pipe is
used only for child status reporting. The delivered-right usability check is a
Mach message sent from parent to child through the delivered descriptor right.

## Cleanup Note

The parent baseline is a full task-port namespace baseline around the probe.

The child cleanup baseline is captured after the child has obtained the
inherited bootstrap/service send right, so it specifically validates cleanup of
the child's cargo receive/send right and verification-message effects. This is
appropriate for the helper-process design and should be described as
child-reported cleanup rather than a process-start absolute namespace.

## Implementation Guidance

rmxOS should match the observable macOS descriptor `MOVE_SEND` contract:

- descriptor `MOVE_SEND` must consume the sender cargo send right at successful
  `mach_msg(SEND)` return
- if the sender also owns the cargo receive right, the sender cargo name remains
  valid as `MACH_PORT_TYPE_RECEIVE`
- receiver receives a usable send right
- receiver-side delivered right reports `MACH_PORT_TYPE_SEND`
- receiver-side delivered right has one observable send ref
- one receiver-side `mach_port_deallocate()` is sufficient for the delivered
  right in this scenario
- parent and child cleanup return to their baselines

Internal `entry_refs` and `srights` counters may be used for implementation
debugging, but the stock macOS oracle contract is the public behavior above.

## Gate Status

OB2.2 is complete on both native macOS runners.

OB2.3 `m2/send_once_descriptor.c` remains blocked until parent accepts this
comparison finding and issues an explicit start instruction.
