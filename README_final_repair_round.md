# MB Final Repair Round

This package documents the final MB repair round that runs the `mb_final_repair_fullnight` profile in all-fresh mode.

## Runtime profile
- profile name: `mb_final_repair_fullnight`
- heights: `500 km`, `750 km`, `1000 km`
- fresh root: `outputs/milestones/MB_20260323_final_repair_fullnight`
- curated delivery root: `outputs/milestones/MB_final_repair_round_delivery`

## Fresh-runtime guarantees
- `cfg.runtime.force_fresh = true`
- `cfg.runtime.regenerate_all_cache = true`
- `cfg.runtime.regenerate_all_export = true`
- `cfg.cache.reuse_semantic = false`
- `cfg.cache.reuse_plot = false`
- `cfg.cache.rebuild_all = true`

## Semantic guarantees in this round
- `historyFull` starts from the original history origin and is padded at the data-table level.
- `effectiveFullRange` stays on the real effective domain and does not pad the front segment.
- `frontierZoom` remains a local frontier window only.
- numeric heatmaps use the minimum-feasible-`Ns` matrix.
- state maps use a separate discrete-state matrix.
- `globalSkeleton` heatmaps use the global `i-P` skeleton, not a local block in a larger axis frame.

## Key tables
- fullnight summary: `outputs/milestones/MB_20260323_final_repair_fullnight/tables/MB_fullnight_run_summary.csv`
- fresh manifest: `outputs/milestones/MB_20260323_final_repair_fullnight/tables/fresh_recompute_manifest.csv`
- passratio root-cause audit: `outputs/milestones/MB_20260323_final_repair_fullnight/tables/plot_domain_root_cause_audit_summary.csv`
- heatmap render audit: `outputs/milestones/MB_20260323_final_repair_fullnight/tables/heatmap_render_mode_audit_summary.csv`
- semantic consistency: `outputs/milestones/MB_20260323_final_repair_fullnight/tables/semantic_domain_consistency_summary.csv`

## Delivery lookup files
- inventory: `outputs/milestones/MB_final_repair_round_delivery/MB_output_inventory.csv`
- recommended roots: `outputs/milestones/MB_final_repair_round_delivery/MB_output_recommended_roots.csv`
- historical map: `outputs/milestones/MB_final_repair_round_delivery/MB_historical_output_map.csv`
- figure index: `outputs/milestones/MB_final_repair_round_delivery/MB_recommended_figure_index.csv`
- canonical figures: `outputs/milestones/MB_final_repair_round_delivery/canonical_figures`
- canonical tables: `outputs/milestones/MB_final_repair_round_delivery/canonical_tables`

## Current fullnight stop-summary
- `500 km`: both `legacyDG` and `closedD` stop at `no_feasible_point_found`
- `750 km`: both `legacyDG` and `closedD` stop at `no_feasible_point_found`
- `1000 km`: `legacyDG=hard_upper_bound_reached`, `closedD=unity_plateau_reached`
