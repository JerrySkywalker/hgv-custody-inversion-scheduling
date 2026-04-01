# Phase 8 summary

## Goal
Integrate a lightweight reference prior into Chapter-5 CK selection.

## Implementation scope
- build a small reference template library from anchor times
- match current window to the nearest visible-compatible template
- use prior deviation as the base-deviation term inside the outerB objective
- compare CK vs CK-prior with C as baseline reference

## Current success criteria
At least one of the following should improve relative to CK:
- switch_count decreases
- mode becomes more stable
- q_worst_window / outage_ratio / longest_outage_steps improves

## Current note
This is a lightweight prior integration version.
It is intended to test whether static-like structural templates can act as useful dynamic scheduling priors.
