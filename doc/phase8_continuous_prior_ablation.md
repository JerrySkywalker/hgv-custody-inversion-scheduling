# Phase08 Continuous Prior Ablation

## Modes
- ck_only
- ck_plus_fragility
- ck_plus_full_prior

## Purpose
Evaluate whether continuous Stage15 prior should be integrated as:
1. a weak soft penalty,
2. fragility-only penalty,
3. full geometric prior penalty.

## Current smoke scope
Representative weak / mid / strong geometry candidates.

## Next engineering step
Locate actual CK / outerA candidate scoring entry and replace:
score_total = score_ck
with:
score_total = score_ck - w_prior * prior_cost_used
through score_candidate_with_continuous_prior().
