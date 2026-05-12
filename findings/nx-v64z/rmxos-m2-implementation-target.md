# rmxOS M2 Implementation Target

Date: 2026-05-13

Status: ready for rmxOS M2 descriptor-transfer implementation.

Source oracle spec:

- `findings/nx-v64z/ob2-core-descriptor-transfer-spec.md`
- `findings/nx-v64z/ob2-core-descriptor-transfer-spec.json`

The following behavior is accepted native macOS contract from both `mx-a64z`
and `mx-x64z`. rmxOS should match it unless parent later approves an
intentional divergence.

## Required Descriptor Semantics

1. COPY_SEND descriptor preserves sender send urefs.

   - sender cargo send urefs remain `1 -> 1 -> 1`
   - sender cargo type remains `SEND_RECEIVE`
   - receiver gets usable `MACH_PORT_TYPE_SEND`
   - delivered send refs are observable as `1`
   - one receiver-side deallocate cleans up the delivered right

2. MOVE_SEND descriptor consumes sender send right at send return.

   - sender cargo send urefs change `1 -> 0 -> 0`
   - sender cargo type changes `SEND_RECEIVE -> RECEIVE`
   - receiver gets usable `MACH_PORT_TYPE_SEND`
   - delivered send refs are observable as `1`
   - one receiver-side deallocate cleans up the delivered right

3. MOVE_SEND_ONCE descriptor delivers a send-once right usable exactly once.

   - send-once creation API is
     `mach_port_extract_right(MACH_MSG_TYPE_MAKE_SEND_ONCE)`
   - receiver gets `MACH_PORT_TYPE_SEND_ONCE`
   - delivered send-once refs are observable as `1`
   - first use succeeds with `MACH_MSG_SUCCESS`
   - second use fails with `MACH_SEND_INVALID_DEST`
   - receiver gets only one verification message

4. Invalid descriptor disposition fails without delivery or consumption.

   - invalid disposition `0xff`
   - send fails with `MACH_SEND_INVALID_RIGHT`
   - no message delivery
   - no right consumption
   - cleanup returns to baseline

5. Nonexistent descriptor source fails without delivery or mutation.

   - send fails with `MACH_SEND_INVALID_RIGHT`
   - no message delivery
   - source remains invalid
   - cleanup returns to baseline

6. Dead-name descriptor source succeeds, delivers, and consumes the dead-name
   entry.

   - source starts as `MACH_PORT_TYPE_DEAD_NAME`
   - send succeeds with `MACH_MSG_SUCCESS`
   - message is delivered
   - dead-name entry is consumed
   - source queries after send return `KERN_INVALID_NAME`
   - cleanup returns to baseline

7. Duplicate MOVE_SEND failure still consumes the sender send right.

   - same send right appears in two descriptors with `MACH_MSG_TYPE_MOVE_SEND`
   - send fails with `MACH_SEND_INVALID_RIGHT`
   - no message delivery
   - sender send right is fully consumed
   - sender cargo type changes `SEND_RECEIVE -> RECEIVE`
   - cleanup returns to baseline

## Mandatory Traps

These are the two easiest places to implement a more logical behavior that is
wrong against macOS:

- dead-name descriptor source succeeds, delivers, and consumes the dead-name
  entry
- duplicate MOVE_SEND failure still consumes the sender send right

Treat both as mandatory rmxOS M2 compatibility targets.

## Comparison Floor

For every rmxOS M2 comparison run, report at least:

- exact call sequence
- exact `mach_msg` return values
- whether a message was delivered
- sender right type before and after send
- sender uref deltas where observable
- receiver delivered right type
- receiver delivered refs where observable
- delivered-right usability
- cleanup-to-baseline result
- semantic classification against the macOS oracle contract

`entry_refs` and `srights` may be included as rmxOS internal evidence, but they
are not the stock macOS oracle contract. In the accepted oracle artifacts,
`entry_refs` are `null` because public macOS APIs do not expose them.

## Scope Boundary

Do not infer descriptor behavior outside the accepted OB2 list. New descriptor
behavior requires a new oracle probe or an explicit parent-approved intentional
divergence.

Deferred oracle work:

- OB2.5 queued cleanup is deferred until rmxOS M2 reaches queued-message
  cleanup, a sender/receiver-exit bug appears, or parent explicitly requests it.
- OB3 process inheritance is deferred until after M2 descriptor transfer is
  implemented or blocked on fork/bootstrap behavior.
