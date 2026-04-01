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

## Phase 7A-3 diagnostics
The debug results showed:
- hard gates screened very few candidates overall
- zero-support-related gates almost never triggered
- the only meaningful screening signal was longest_single_support
Therefore, the next revision should make single-support fragility the dominant criterion.

## Phase 7A-4 change
- tighten longest_single gates in warn / trigger
- greatly increase single_support and longest_single weights
- apply lexicographic ranking in warn / trigger:
  1) shortest longest_single_support_steps
  2) smallest single_support_ratio
  3) lowest total score

## Current note
This revision makes single-support fragility the primary decision axis of outerB.
