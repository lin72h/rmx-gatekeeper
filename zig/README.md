# Zig Probe Layout

Standalone Zig binaries are the canonical native probe format for M1 and later
oracle work. Elixir owns orchestration, artifact parsing, and certification
logic; Zig owns portable probe binaries and ABI/semantic checks.

Initial layout:

- `zig/probes/mach/`
- `zig/probes/dispatch/`
- `zig/probes/launchd/`
- `zig/probes/libthr/`

M1 does not migrate existing C or Zig probes into this layout. Existing C remains
reference material until Zig parity passes.
