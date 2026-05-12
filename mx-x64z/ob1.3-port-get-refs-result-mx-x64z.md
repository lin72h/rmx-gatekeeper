# mx-x64z OB1.3 Port Get Refs Result

Date: 2026-05-12

Agent: `mx-x64z`

Probe: `foundation/port_get_refs.c`

Test ID: `macos_foundation_port_get_refs`

Scope: OB1.3 only. No header COPY_SEND/MOVE_SEND or descriptor probes were
started.

## Host Identity

```text
uname -m: x86_64
ProductName: macOS
ProductVersion: 26.4
BuildVersion: 25E246
Darwin kernel: 25.4.0
Runner class: native Intel macOS
Agent: mx-x64z
```

Environment JSON reported:

```text
os_name: Darwin
arch: x86_64
machine: x86_64
rosetta: unknown
sip_enabled: true
sandboxed: false
run_as_root: false
ad_hoc_signed: true
hardened_runtime: false
sdk_version: 26.5
sdk_path: /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
xcode_select_path: /Applications/Xcode.app/Contents/Developer
```

## Commands Run

```sh
git pull --ff-only
cd macos-validation
make clean all
make run AGENT=mx-x64z
make validate-json
```

## Result Directory

```text
/Users/linz/Local/wip-mach/mach-oracle/macos-validation/results/mx-x64z/20260512-26.4-25.4.0
```

Raw artifacts selected for force-add:

```text
macos-validation/results/mx-x64z/20260512-26.4-25.4.0/environment.json
macos-validation/results/mx-x64z/20260512-26.4-25.4.0/foundation_port_get_refs.json
```

Stderr logs were empty:

```text
foundation_port_get_refs.stderr.log: 0 bytes
foundation_port_names.stderr.log: 0 bytes
foundation_port_type.stderr.log: 0 bytes
foundation_smoke.stderr.log: 0 bytes
signing.stderr.log: 0 bytes
```

## Build And Validation Result

```text
Running: foundation/port_get_refs ...
  PASS: foundation/port_get_refs
Running: foundation/port_names ...
  PASS: foundation/port_names
Running: foundation/port_type ...
  PASS: foundation/port_type
Running: foundation/smoke ...
  PASS: foundation/smoke

Summary: 4 probes, 4 pass, 0 fail, 0 skip
Validated: 7 files, 7 pass, 0 fail
```

## Port Get Refs Result

Top-level fields from `foundation_port_get_refs.json`:

```text
schema: nx-v64z.macos-oracle.v1
agent: mx-x64z
test_id: macos_foundation_port_get_refs
status: pass
semantic_class: exact_contract
cleanup.returned_to_baseline: true
cleanup.notes:
notes:
```

Mach return sequence:

```text
mach_port_names_before: KERN_SUCCESS (0)
mach_port_allocate_receive: KERN_SUCCESS (0)
mach_port_get_refs_receive_initial: KERN_SUCCESS (0)
mach_port_get_refs_send_before_make: KERN_SUCCESS (0)
mach_port_insert_right_make_send: KERN_SUCCESS (0)
mach_port_get_refs_send_after_make: KERN_SUCCESS (0)
mach_port_mod_refs_send_plus_one: KERN_SUCCESS (0)
mach_port_get_refs_send_after_mod_plus: KERN_SUCCESS (0)
mach_port_deallocate_send: KERN_SUCCESS (0)
mach_port_get_refs_send_after_deallocate: KERN_SUCCESS (0)
mach_port_mod_refs_send_minus_one: KERN_SUCCESS (0)
mach_port_get_refs_send_after_mod_minus: KERN_SUCCESS (0)
mach_port_get_refs_receive_final: KERN_SUCCESS (0)
mach_port_destroy_receive: KERN_SUCCESS (0)
mach_port_names_after: KERN_SUCCESS (0)
```

Observed refs:

| Label | Return | Refs | Expected | Match |
| --- | --- | ---: | ---: | --- |
| receive initial | `KERN_SUCCESS` | 1 | 1 | true |
| send before `MAKE_SEND` | `KERN_SUCCESS` | 0 | 0 | true |
| send after `MAKE_SEND` | `KERN_SUCCESS` | 1 | 1 | true |
| send after `mach_port_mod_refs +1` | `KERN_SUCCESS` | 2 | 2 | true |
| send after `mach_port_deallocate` | `KERN_SUCCESS` | 1 | 1 | true |
| send after `mach_port_mod_refs -1` | `KERN_SUCCESS` | 0 | 0 | true |
| receive after send cleanup | `KERN_SUCCESS` | 1 | 1 | true |

Right deltas:

```json
[
  {
    "operation": "allocate receive right",
    "port_name": "port_get_refs_probe_port",
    "right_type": "MACH_PORT_RIGHT_RECEIVE",
    "before_urefs": null,
    "after_urefs": 1,
    "entry_refs_before": null,
    "entry_refs_after": null,
    "expected": "receive urefs exactly 1"
  },
  {
    "operation": "make send right",
    "port_name": "port_get_refs_probe_port",
    "right_type": "MACH_PORT_RIGHT_SEND",
    "before_urefs": null,
    "after_urefs": 1,
    "entry_refs_before": null,
    "entry_refs_after": null,
    "expected": "send urefs exactly 1"
  },
  {
    "operation": "mach_port_mod_refs SEND +1",
    "port_name": "port_get_refs_probe_port",
    "right_type": "MACH_PORT_RIGHT_SEND",
    "before_urefs": 1,
    "after_urefs": 2,
    "entry_refs_before": null,
    "entry_refs_after": null,
    "expected": "incremented by 1"
  },
  {
    "operation": "mach_port_deallocate SEND",
    "port_name": "port_get_refs_probe_port",
    "right_type": "MACH_PORT_RIGHT_SEND",
    "before_urefs": 2,
    "after_urefs": 1,
    "entry_refs_before": null,
    "entry_refs_after": null,
    "expected": "decremented by 1"
  },
  {
    "operation": "mach_port_mod_refs SEND -1",
    "port_name": "port_get_refs_probe_port",
    "right_type": "MACH_PORT_RIGHT_SEND",
    "before_urefs": 1,
    "after_urefs": 0,
    "entry_refs_before": null,
    "entry_refs_after": null,
    "expected": "send urefs decremented to 0"
  }
]
```

`entry_refs_before` and `entry_refs_after` are intentionally `null`; stock
macOS does not expose kernel entry refs.

Cleanup observation:

```json
{
  "names_before": 12,
  "names_after": 12,
  "cleanup_delta": 0
}
```

## Parent-Facing Finding

For OB1.3 on native Intel macOS, rmxOS should match this observable contract:

```text
mach_port_get_refs(RECEIVE) on a newly allocated receive right returns 1.
mach_port_get_refs(SEND) before MAKE_SEND returns KERN_SUCCESS with refs 0.
MACH_MSG_TYPE_MAKE_SEND creates one observable send uref.
mach_port_mod_refs(SEND, +1) increments send urefs from 1 to 2.
mach_port_deallocate() decrements send urefs from 2 to 1.
mach_port_mod_refs(SEND, -1) decrements send urefs from 1 to 0.
Receive urefs remain 1 after send cleanup.
Cleanup returns exactly to baseline with cleanup_delta 0.
```

The `mx-x64z` lane did not hit a stop condition: user refs changed
predictably, all raw return values were recorded, entry refs remained null, and
cleanup returned to baseline.
