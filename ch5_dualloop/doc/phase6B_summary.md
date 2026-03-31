# Phase 6B summary

## Scope
Validate whether standalone outerA alerts align with bad phi windows.

## Phase 6B-1 changes
- replace single-point bad segments with bad-window definition
- compare two alert modes:
  - trigger_only
  - warn_or_trigger

## Goal
Test whether outerA is a useful early-warning layer before entering true CK dual-loop scheduling.

## Files
- analysis/match_outerA_events_to_bad_segments.m
- plots/plot_outerA_vs_phi_alignment.m
- runners/run_ch5_phase6B_outerA_alignment.m

## Key outputs
- bad window count
- trigger_only hit / miss / false alarm metrics
- warn_or_trigger hit / miss / false alarm metrics
- lead-time metrics under both alert modes

## Current note
If warn_or_trigger works materially better than trigger_only,
then outerA should be interpreted as a two-level warning layer,
not a pure hard-trigger layer.
