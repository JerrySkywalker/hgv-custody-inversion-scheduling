# Phase 7A summary

## Phase 7A outcome
The first minimal CK version ran successfully but failed methodologically:
- RMSE changed only slightly
- custody metrics degraded
- the policy still behaved too much like tracking / average-visibility logic

## Phase 7A-1 outcome
The first worst-window revision also failed:
- outerB degenerated to one-satellite solutions
- C remained on two-satellite support
- CK lost dual-satellite redundancy and custody collapsed

## Phase 7A-2 outcome
The custody-structure-constrained revision recovered dual-satellite support:
- CK no longer collapsed to one-satellite solutions
- coverage_ratio_ge2 recovered to 1
- but CK still underperformed C on custody metrics

## Phase 7A-3 change
Add hard-gated worst-window protection into outerB:

- keep the dual-satellite preference from 7A-2
- add hard feasibility gates in warn / trigger
- reject or strongly penalize candidate sets with:
  - too much zero-support ratio
  - too long zero-support segments
  - too long single-support segments
- choose feasible custody sets first, then use fallback only if no feasible set exists

## Files
- outer_loop_B/is_support_pattern_feasible_dualloop.m
- outer_loop_B/build_window_objective_dualloop.m
- outer_loop_B/select_satellite_set_custody_dualloop.m

## Current note
This revision is intended to move outerB from soft-penalty risk aversion to hard-gated worst-window protection.
The key test is whether CK can now narrow or reverse the custody gap relative to C.
