# OB1.3 Cross-Runner Comparison

Date: 2026-05-12

Probe: `foundation/port_get_refs.c`

Test ID: `macos_foundation_port_get_refs`

| Runner | Status | Kernel | Arch | Receive Initial | Send Before MAKE_SEND | Send After MAKE_SEND | After SEND +1 | After Deallocate | After SEND -1 | Cleanup Baseline |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `mx-a64z` | `pass` | `25.5.0` | `arm64` | 1 | 0 | 1 | 2 | 1 | 0 | true |
| `mx-x64z` | `pass` | `25.4.0` | `x86_64` | 1 | 0 | 1 | 2 | 1 | 0 | true |

Cross-runner finding: both native macOS runners agree for OB1.3. Receive refs
start at 1, send refs are observable as `KERN_SUCCESS` with value 0 before
`MAKE_SEND`, `MAKE_SEND` creates send refs 1, `SEND +1` raises them to 2,
`mach_port_deallocate()` lowers them to 1, `SEND -1` lowers them to 0, and
cleanup returns to baseline.

Gate status: OB1.3 is passed on both native macOS runners. Header
COPY_SEND/MOVE_SEND remains unstarted in this `mx-x64z` turn.
