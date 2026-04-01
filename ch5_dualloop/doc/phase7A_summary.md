# Phase 7A summary

## Scope
Minimal CK closed-loop based on outerA mode-driven dispatch.

## Phase 7A outcome
The first minimal CK version ran successfully but failed methodologically:
- RMSE improved slightly
- custody metrics degraded
This indicated that the old outerB objective was still too close to tracking / average-visibility logic.

## Phase 7A-1 change
Replace the outerB objective with a worst-window-oriented custody objective:

- maximize predicted phi_min
- maximize predicted phi_avg
- penalize predicted outage ratio
- penalize predicted longest outage
- penalize deviation from reference template
- penalize switching

## Files
- outer_loop_B/compute_phi_window_proxy_dualloop.m
- outer_loop_B/select_reference_template_dualloop.m
- outer_loop_B/build_window_objective_dualloop.m
- outer_loop_B/select_satellite_set_custody_dualloop.m

## Current note
This is the first implementation that is truly aligned with the chapter-5 method statement.
The key test is whether CK can stop harming custody metrics and begin improving the floor-related metrics over C.
