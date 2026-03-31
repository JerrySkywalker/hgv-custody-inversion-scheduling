# Phase 6B summary

## Scope
Validate whether standalone outerA trigger events align with bad phi segments.

## Goal
Move from "outerA can output evidence" to "outerA evidence is meaningfully aligned with bad segments".

## Files
- analysis/match_outerA_events_to_bad_segments.m
- plots/plot_outerA_vs_phi_alignment.m
- runners/run_ch5_phase6B_outerA_alignment.m

## Key outputs
- bad segment count
- trigger event count
- hit count / miss count / false alarm count
- hit rate / miss rate / false alarm rate
- mean lead time to bad segments

## Current note
Phase 6B still does not close the loop.
Its purpose is to validate whether outerA is a useful trigger layer before entering real CK dual-loop design.
