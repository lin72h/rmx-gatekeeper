# OB1.3 Cross-Runner Comparison

Date: 2026-05-12

Probe: `foundation/port_get_refs.c`

Test ID: `macos_foundation_port_get_refs`

| Runner | Status | Kernel | Arch | Receive Initial | Send Before MAKE_SEND | Send After MAKE_SEND | After SEND +1 | After Deallocate | After SEND -1 | Cleanup Baseline |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `mx-a64z` | `pass` | `25.5.0` | `arm64` | 1 | 0 | 1 | 2 | 1 | 0 | true |
| `mx-x64z` | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |

Current comparison status: incomplete until the native Intel runner publishes
its OB1.3 raw `foundation_port_get_refs.json`.

Do not start header COPY_SEND/MOVE_SEND until both `mx-a64z` and `mx-x64z`
have passing OB1.3 results with no cleanup drift.
