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

## Phase 7A-2 change
Introduce custody-structure constraints into outerB:

- in warn / trigger, prefer dual-satellite legal actions
- explicitly score future dual-support ratio
- explicitly penalize future single-support ratio
- explicitly penalize future zero-support ratio
- penalize longest single-support segment
- penalize longest zero-support segment
- preserve reference-template and switching regularization

## Files
- outer_loop_B/compute_support_window_proxy_dualloop.m
- outer_loop_B/select_reference_template_dualloop.m
- outer_loop_B/build_window_objective_dualloop.m
- outer_loop_B/select_satellite_set_custody_dualloop.m

## Current note
This revision is intended to prevent outerB from collapsing to fragile one-satellite solutions.
The key test is whether CK recovers dual-satellite support and stops the custody metrics from exploding.
