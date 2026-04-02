# WS-5-R4

## Goal
Run a 2-D sensitivity scan over:
- template_filter_topk
- library_pair_cap

and export both text and figures for manual inspection.

## Metrics
- ratio_changed_B_vs_A
- ratio_changed_C_vs_A
- ratio_changed_C_vs_B
- mean_num_all_candidates
- mean_num_kept_candidates
- mean_compression_ratio
- mean_match_distance_B
- mean_match_distance_C

## Figures
- heatmap: ratio_changed_C_vs_A
- heatmap: mean_compression_ratio
- line: ratio_changed_C_vs_A vs topK
- line: mean_compression_ratio vs topK
- line: ratio_changed_C_vs_A vs library cap
- line: mean_compression_ratio vs library cap

## Notes
This round remains analysis-only.
No baseline objective formula is changed.
