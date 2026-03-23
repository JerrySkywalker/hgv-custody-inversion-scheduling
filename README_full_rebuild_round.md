# MB Full Rebuild Round

This round replaces sparse-projection plotting with true data-source semantics for MB pass-ratio and heatmap exports.

## Runtime profile
- strict replica root: `outputs/milestones/MB_20260323_globalfulldense_strict`
- baseline full rebuild root: `outputs/milestones/MB_20260323_globalfulldense_baseline`
- curated delivery root: `outputs/milestones/MB_20260323_globalfulldense_delivery`
- heights: `500 km`, `750 km`, `1000 km`
- sensor group: `baseline`

## Full-rebuild guarantees
- `cfg.milestones.MB_semantic_compare.force_rebuild_all_cache = true`
- `cfg.runtime.force_fresh = true`
- `cfg.runtime.regenerate_all_cache = true`
- `cfg.runtime.regenerate_all_export = true`
- `cfg.cache.reuse_semantic = false`
- `cfg.cache.reuse_plot = false`

## Pass-ratio semantics in this round
- `historyFull` plots true computed history points only, in ascending `Ns`, with no zero padding.
- `effectiveFullRange` is rebuilt on the full effective `Ns` grid instead of windowing a sparse source table.
- `globalFullDense` is rebuilt on the full search-domain `Ns` grid from `Ns_initial_min` through the final `Ns_max`, with no zero padding and no sparse tail slicing.
- `frontierZoom` is cut from the dense `effectiveFullRange` table instead of being drawn from sparse tail data.
- `globalTrend` is no longer exported as an alias, because it had no independent data semantics.
- default primary pass-ratio figure for citation is now `globalFullDense`; `effectiveFullRange` remains the effective-domain analysis view.

## Heatmap semantics in this round
- `numeric_requirement + local` remains a local requirement surface.
- `numeric_requirement + globalSkeleton` is rebuilt on the global `i-P` grid instead of projecting a local block onto a skeleton.
- `state_map + globalSkeleton` remains a discrete coverage/state map and distinguishes undefined/uncomputed, evaluated infeasible, boundary suspect, internally defined, and refined/overcompute cells.
- default primary heatmap for citation is `numeric globalSkeleton`; `state_map globalSkeleton` remains the supporting diagnostic/state figure.

## Recommended citation roots
- current canonical baseline: `outputs/milestones/MB_20260323_globalfulldense_baseline`
- current curated bundle: `outputs/milestones/MB_20260323_globalfulldense_delivery`
- current strict replica anchor: `outputs/milestones/MB_20260323_globalfulldense_strict`

## Historical roots retained but not recommended
- `outputs/milestones/MB_20260323_final_repair_fullnight`
- `outputs/milestones/MB_final_repair_round_delivery`
- `outputs/milestones/MB`

## Key validation tables
- strict replica: `outputs/milestones/MB_20260323_globalfulldense_strict/tables/MB_stage05_strictReplica_validation_summary.csv`
- passratio semantics audit: `outputs/milestones/MB_20260323_globalfulldense_baseline/tables/passratio_source_semantics_audit_summary.csv`
- heatmap semantics audit: `outputs/milestones/MB_20260323_globalfulldense_baseline/tables/heatmap_source_semantics_audit_summary.csv`
- round closure: `outputs/milestones/MB_20260323_globalfulldense_baseline/tables/MB_full_rebuild_closure_summary.csv`
- fresh manifest: `outputs/milestones/MB_20260323_globalfulldense_baseline/tables/fresh_recompute_manifest.csv`
