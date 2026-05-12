# OB1.5 Cross-Runner Comparison

Date: 2026-05-13

Probe: `m1/header_move_send_accounting.c`

Test ID: `macos_m1_header_move_send_accounting`

| Runner | Status | Kernel | Arch | Send Urefs | Port Type Sequence | Sent Bits | Received Bits | Received Ports | Cleanup Baseline |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `mx-a64z` | `pass` | `25.5.0` | `arm64` | `1 -> 0 -> 0` | `SEND_RECEIVE -> RECEIVE -> RECEIVE` | `0x11` | `0x1100` | `MACH_PORT_NULL` / `service_port` | true |
| `mx-x64z` | `pass` | `25.4.0` | `x86_64` | `1 -> 0 -> 0` | `SEND_RECEIVE -> RECEIVE -> RECEIVE` | `0x11` | `0x1100` | `MACH_PORT_NULL` / `service_port` | true |

Both native macOS runners agree for OB1.5. Header
`MACH_MSG_TYPE_MOVE_SEND` consumes the sender's observable send right at
successful `mach_msg(SEND)` return. The sender remains with only the receive
right after send and after receive.

The received header is also consistent across runners:

- received remote disposition: `0`
- received local disposition: `MACH_MSG_TYPE_MOVE_SEND`
- received remote port: `MACH_PORT_NULL`
- received local port: `service_port`

Stock macOS does not expose entry refs here, so the raw JSON keeps
`entry_refs_before` and `entry_refs_after` as `null`.

Gate status: OB1.5 passed on both native macOS runners. OB2 remains unstarted
in this lane; OB2.1 must wait for the next explicit parent start instruction.
