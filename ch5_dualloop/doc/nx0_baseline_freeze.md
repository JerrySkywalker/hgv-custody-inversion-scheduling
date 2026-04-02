# NX-0 Baseline Freeze

## Purpose

This note freezes the current Chapter 5 baseline and records the routing decision after the latest Phase7A / Phase8 integration tests.

The goal is to prevent future development from drifting back into the already-tested but currently unsuitable path of stepwise hard prior / hard template filtering.

---

## Frozen baseline

The formal Chapter 5 dynamic baseline is now:

- **Method name**: `CK`
- **Source**: `Phase7A`
- **Meaning**: custody-oriented dual-loop baseline

The current engineering interpretation is:

- `C` = custody-oriented single-loop reference baseline
- `CK` = custody-oriented dual-loop baseline
- all later methods must be compared against `CK`, not against exploratory prior/filter variants

---

## What is frozen

The following points are now considered frozen engineering consensus:

1. `Phase7A` is the stable mainline baseline for Chapter 5 dynamic experiments.
2. `reference-only` currently does **not** materially change the online CK decision chain.
3. direct stepwise hard template filtering is **not** a valid default enhancement path for CK.
4. future development must move toward:
   - state-machine-driven switching
   - guarded switching logic
   - proposal/diagnostic usage of template knowledge
   rather than direct hard filtering at every step.

---

## Consequence for later stages

From this point onward:

- `CK` remains the formal baseline.
- prior/template/filter logic is treated as:
  - analysis mode
  - proposal mode
  - diagnostics / explainability mode
until a state-machine-constrained integration proves otherwise.

This freeze is a **routing correction**, not a rejection of the dissertation direction.
The negative result only rejects one specific bridging method:
"static template -> stepwise hard online filter".

---

## Immediate next-stage direction

The next development focus should be:

1. isolate why `CK` works (ablation)
2. build a custody state machine with dwell / hysteresis / guarded switching
3. re-introduce template information only under state-machine control

This marks the end of the transition-period assumption that direct balanced filtering could serve as a default online enhancement.
