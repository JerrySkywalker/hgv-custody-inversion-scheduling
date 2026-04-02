# WS-1-R1

## Goal
Enhance the existing Phase 7B ablation so that it reports:
- selected-set comparison
- candidate-score dump on differing steps

## Scope
This round keeps the minimal ablation set unchanged:
- C baseline
- CK full
- CK without geometry

## Diagnostics included
1. Selected-set comparison:
   - C vs CK
   - CK vs CK-noGeom

2. Candidate score dumps on first few CK-vs-noGeom differing steps.

## Deferred
OuterB diagnose is deferred to WS-1-R2 because the current helper expects
config fields that are not present in the current default_ch5_params baseline.

## Expected outcome
This round should already support a mechanism-level statement:
geometry changes candidate ranking / selected sets, not merely summary metrics.
