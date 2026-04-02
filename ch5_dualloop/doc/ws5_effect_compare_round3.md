# WS-5-R3

## Goal
Upgrade WS-5 from single-step smoke to multi-step quantitative comparison.

## Compared modes
1. baseline
2. reference_only
3. reference_plus_filter

## Exported quantities
For each valid k:
- selected_A / selected_B / selected_C
- changed_B_vs_A
- changed_C_vs_A
- changed_C_vs_B
- num_all_candidates
- num_kept_candidates
- compression_ratio
- template family / match distance
- filter keep idx / keep distances

## Aggregate summary
- ratio_changed_B_vs_A
- ratio_changed_C_vs_A
- ratio_changed_C_vs_B
- mean_num_all_candidates
- mean_num_kept_candidates
- mean_compression_ratio
- min/max compression_ratio
- mean_match_distance_B / C

## Notes
This round still does not change the baseline objective formula.
It only quantifies the structural effect of reference selection and filtering.
