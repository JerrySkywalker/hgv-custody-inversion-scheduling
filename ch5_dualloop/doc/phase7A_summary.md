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

## Phase 7A-3 outcome
Hard-gated worst-window protection was added, but results remained unchanged from 7A-2.
This indicates the new gates may not actually be screening candidate sets in practice.

## Phase 7A-3-dbg purpose
Diagnose:
- outerA safe / warn / trigger ratios
- how many candidate sets are feasible each step
- whether the selected set is feasible
- which gate reasons are actually triggered

## Files
- analysis/summarize_outerA_mode_series.m
- analysis/diagnose_outerB_selection_dualloop.m
- runners/run_ch5_phase7A3_debug.m
