# NX-1 CK Ablation

## Purpose

NX-1 isolates which parts of the current `CK` chain are actually responsible for its observed benefits.

The immediate engineering question is:

- does `CK` mainly benefit from geometry terms?
- from mode/state switching?
- from conservative evidence correction?
- or from some combination of them?

This first round establishes a stable ablation entrypoint with four methods:

- `C-baseline`
- `CK-full`
- `CK-noGeom`
- `CK-noStateMachine`

## Output metrics

The first-round ablation exports:

- `q_worst_window`
- `phi_mean`
- `outage_ratio`
- `longest_outage_steps`
- `mean_rmse`
- `max_rmse`
- `switch_count`

## Current expectation

If the current core already consumes the ablation toggles, then:

- `CK-noGeom` should move toward weaker worst-window custody quality
- `CK-noStateMachine` should typically show weaker continuity and/or unstable switching

If the results remain identical to `CK-full`, that means the runner layer is ready but the core has not yet consumed the toggles.
That is still a valid first-round result because it cleanly separates:
- interface readiness
- core logic readiness

## Status

This note belongs to the first round only.
Later rounds may add:

- `CK-noConservativeEvidence`
- `CK-noWarnTriggerSplit`
- scene sweep summaries
