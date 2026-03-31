# Phase 6A summary

## Scope
Standalone outerA RF-Koopman evidence layer.

## Goal
Build demand-side risk evidence without closing the dual-loop policy.

## Files
- outer_loop_A/rfkoopman_fit_local_operator.m
- outer_loop_A/propagate_rfkoopman_window.m
- outer_loop_A/compute_mr_hat.m
- outer_loop_A/conservative_mr_from_nis.m
- outer_loop_A/compute_omega_max.m
- outer_loop_A/classify_outerA_risk_state.m
- outer_loop_A/package_outerA_result.m
- metrics/eval_dualloop_metrics.m
- plots/plot_dualloop_evidence_timeline.m
- plots/plot_outerA_quadrant_stats.m
- runners/run_ch5_phase6_outerA_rfkoopman.m

## Phase 6A-1 stabilization changes
- add spectral-radius clipping for local Koopman operator
- standardize fit-window evidence before operator fitting
- clip propagated phi / nis / candidate-count predictions
- bound NIS-driven conservative inflation
- replace raw omega diff with bounded growth-rate metric
- retune warn / trigger thresholds to reduce over-triggering

## Phase 6A-1b robust fitting changes
- inspect local design matrix rank by SVD
- use ridge least squares when full-rank
- use low-rank subspace fitting when rank-deficient but still usable
- fall back to identity dynamics when effective rank is too low
- reduce singular / rank-deficient warnings at the fitter source

## Expected outputs
- evidence timeline
- quadrant/state ratio plot
- trigger count
- lead-time statistics

## Current note
This phase is standalone. It does not yet claim CK superiority.
Its purpose is to validate whether outerA can produce structured future-risk evidence.
Phase 6A-1 focuses on numerical stabilization and threshold calibration.
Phase 6A-1b focuses on robust local Koopman fitting under rank deficiency.
