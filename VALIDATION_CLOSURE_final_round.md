# Validation Closure Final Round

## Strict replica
- file: `outputs/milestones/MB_20260324_globalfullreplay_strict/tables/MB_stage05_strictReplica_validation_summary.csv`
- expected: `max_abs_diff_over_curve = 0`, `max_abs_diff = 0`

## Pass-ratio semantics
- `historyFull`: real points only, no zero padding, no gap bridging
- `effectiveFullRange`: effective-domain dense rebuild, clearly marked `effective_only`
- `globalFullReplay`: full-domain replay, gaps remain broken, no tail-only aliasing
- `frontierZoom`: local zoom cut from dense effective replay

## Heatmap semantics
- `local`: effective/local defined surface only
- `globalReplay`: full-frame replay with undefined cells preserved
- numeric and state matrices are audited separately

## Required closure tables
- `outputs/milestones/MB_20260324_globalfullreplay_baseline/tables/passratio_source_semantics_audit_summary.csv`
- `outputs/milestones/MB_20260324_globalfullreplay_baseline/tables/passratio_view_scope_audit_summary.csv`
- `outputs/milestones/MB_20260324_globalfullreplay_baseline/tables/passratio_tail_oscillation_audit.csv`
- `outputs/milestones/MB_20260324_globalfullreplay_baseline/tables/heatmap_source_semantics_audit_summary.csv`
- `outputs/milestones/MB_20260324_globalfullreplay_baseline/tables/heatmap_view_scope_audit_summary.csv`
- `outputs/milestones/MB_20260324_globalfullreplay_baseline/tables/plot_domain_root_cause_audit_summary.csv`
- `outputs/milestones/MB_20260324_globalfullreplay_baseline/tables/MB_full_rebuild_closure_summary.csv`
