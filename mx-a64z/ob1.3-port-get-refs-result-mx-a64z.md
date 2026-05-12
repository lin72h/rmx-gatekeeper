# mx-a64z OB1.3 Port Get Refs Result

Date: 2026-05-12

Agent: `mx-a64z`

Probe: `foundation/port_get_refs.c`

Test ID: `macos_foundation_port_get_refs`

## Host

```text
uname -m: arm64
sw_vers:
  ProductName: macOS
  ProductVersion: 26.5
  BuildVersion: 25F71
uname -r: 25.5.0
sysctl.proc_translated: 0
```

Native Apple Silicon. Rosetta is not active.

## Commands

```sh
git pull --ff-only
cd macos-validation
make clean all
make run AGENT=mx-a64z
make validate-json
```

## Result Directory

```text
/Users/linz/Local/wip-mach/mach-oracle/macos-validation/results/mx-a64z/20260512-26.5-25.5.0
```

Raw artifacts force-added for commit:

```text
macos-validation/results/mx-a64z/20260512-26.5-25.5.0/environment.json
macos-validation/results/mx-a64z/20260512-26.5-25.5.0/foundation_port_get_refs.json
```

Empty stderr logs were not force-added:

```text
foundation_port_get_refs.stderr.log: 0 bytes
foundation_port_names.stderr.log: 0 bytes
foundation_port_type.stderr.log: 0 bytes
foundation_smoke.stderr.log: 0 bytes
signing.stderr.log: 0 bytes
```

## Harness Summary

```text
Summary: 4 probes, 4 pass, 0 fail, 0 skip
Validated: 6 files, 6 pass, 0 fail
```

Validation included the previously committed `mx-x64z` OB1.1 and OB1.2 raw
JSON artifacts in addition to this runner's current result directory.

## Port Get Refs Result

```json
{
  "agent": "mx-a64z",
  "test_id": "macos_foundation_port_get_refs",
  "status": "pass",
  "semantic_class": "exact_contract",
  "returns": [
    {
      "call": "mach_port_names_before",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_allocate_receive",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_get_refs_receive_initial",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_get_refs_send_before_make",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_insert_right_make_send",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_get_refs_send_after_make",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_mod_refs_send_plus_one",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_get_refs_send_after_mod_plus",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_deallocate_send",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_get_refs_send_after_deallocate",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_mod_refs_send_minus_one",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_get_refs_send_after_mod_minus",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_get_refs_receive_final",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_destroy_receive",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    },
    {
      "call": "mach_port_names_after",
      "returned": "KERN_SUCCESS",
      "raw": 0,
      "errno": null
    }
  ],
  "right_deltas": [
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
      "expected": "send urefs decremented to zero"
    }
  ],
  "observations": {
    "receive_refs_initial": 1,
    "send_refs_before_make": 0,
    "send_refs_before_make_zero": true,
    "send_refs_before_make_return": "KERN_SUCCESS",
    "send_refs_after_make": 1,
    "send_refs_after_mod_plus": 2,
    "send_refs_after_deallocate": 1,
    "send_refs_after_mod_minus": 0,
    "send_refs_after_mod_minus_zero": true,
    "send_refs_after_mod_minus_return": "KERN_SUCCESS",
    "receive_refs_final": 1,
    "names_before": 11,
    "names_after": 11,
    "cleanup_delta": 0
  },
  "cleanup": {
    "returned_to_baseline": true,
    "notes": ""
  },
  "notes": ""
}
```

## Finding

On native Apple Silicon macOS 26.5 / Darwin 25.5.0,
`mach_port_get_refs()` matches the OB1.3 observable uref contract:

- allocated receive right has receive urefs `1`
- send urefs before `MACH_MSG_TYPE_MAKE_SEND` are observable as
  `KERN_SUCCESS` with value `0`
- `MACH_MSG_TYPE_MAKE_SEND` creates send urefs `1`
- `mach_port_mod_refs(..., MACH_PORT_RIGHT_SEND, +1)` changes send urefs
  from `1` to `2`
- `mach_port_deallocate()` changes send urefs from `2` to `1`
- `mach_port_mod_refs(..., MACH_PORT_RIGHT_SEND, -1)` changes send urefs
  from `1` to `0`
- receive urefs remain `1` before destroying the receive right
- `entry_refs_before` and `entry_refs_after` remain `null`
- cleanup returned exactly to baseline

No OB1.3 stop condition occurred on `mx-a64z`.
