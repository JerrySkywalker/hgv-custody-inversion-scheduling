# Phase 7A summary

## Scope
Minimal CK closed-loop based on outerA mode-driven dispatch.

## Goal
Move from standalone outerA evidence to a real CK policy:
- safe -> maintain
- warn -> reinforce
- trigger -> reconfigure/emergency

## Files
- outer_loop_B/dispatch_quadrant_policy.m
- outer_loop_B/build_window_objective_dualloop.m
- outer_loop_B/select_satellite_set_custody_dualloop.m
- policies/policy_custody_dualloop_koopman.m
- plots/plot_ck_vs_c_summary.m
- runners/run_ch5_phase7A_dualloop_ck.m

## Current note
This is a minimal working CK baseline.
The main purpose is to verify whether mode-driven outerB can beat or at least differ meaningfully from C.
