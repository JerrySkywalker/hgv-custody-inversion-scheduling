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

## Phase 7A-3 / 7A-4 outcome
The later gate/lexicographic revisions did not change the final metrics relative to 7A-2.

## Phase 7A-select-dbg purpose
Directly inspect:
- when C and CK choose different sets
- which candidate sets exist at those steps
- how those sets differ in longest_single_support, single_support_ratio, zero_support_ratio, and total score

## Files
- analysis/compare_selected_sets_dualloop.m
- analysis/dump_candidate_scores_dualloop.m
- runners/run_ch5_phase7A_select_debug.m
