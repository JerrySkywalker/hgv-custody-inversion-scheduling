# WS-1-R1

## Goal
Enhance the existing Phase 7B ablation so that it not only reports summary metrics, but also explains why geometry matters.

## Scope
This round keeps the minimal ablation set unchanged:
- C baseline
- CK full
- CK without geometry

No Phase08 prior is involved in this round.

## Added diagnostics
1. Selected-set comparison:
   - C vs CK
   - CK vs CK-noGeom

2. OuterB selection diagnosis:
   - feasible-set ratio
   - no-feasible ratio
   - selected-two-sat ratio
   - gate reason counts

3. Candidate score dumps on first few CK-vs-noGeom differing steps.

## Expected outcome
This round should support a mechanism-level statement:
geometry improves custody-oriented selection quality through outerB ranking/gating,
rather than mainly improving tracking RMSE.

## Notes
- Phase7A baseline remains frozen.
- This round does not modify policy_custody_dualloop_koopman.
- This round does not change build_window_objective_dualloop baseline logic.
