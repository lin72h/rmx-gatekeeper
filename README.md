# rmx-gatekeeper — Gatekeeper Ruler

This repository is the **Gatekeeper ruler** for the rmxOS / NextBSD-revival parity track
(rmrOS side; `rmx-gatekeeper-rx-x64z`). It enforces evidence discipline, gates guest
spends, and **runs the Explorer's macOS-27 parity tests as a validation suite against the
Implementer's build** — so foundation-completion work is proven solid against macOS, not by
assertion.

**Read `ONBOARDING.md` first** — it defines your role, the validation-suite interlock, the
current phase, and what changed when the old unified oracle was split into dedicated rulers.

- `ONBOARDING.md` — current-state briefing (authoritative; read first).
- `AGENTS.md` — operational rulebook (change-lanes, attempt accounting, evidence ceremony,
  guest-run discipline). Still valid — this is your core gate rulebook.
- `archive/` — pre-split historical planning/coordination docs. Reference only; do not act
  on decisions there — they predate the split and may use retired terms (`oracle`,
  `nx-v64z`). `ONBOARDING.md` / `AGENTS.md` win on any conflict.

The Explorer is a separate agent (`rmx-explorer`); you consume its vectors + ledger
**read-only** across the repo boundary.
