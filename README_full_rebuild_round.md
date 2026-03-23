# MB Full Rebuild Round

This round replaces mixed plotting semantics with explicit replay/effective/history contracts.

## Runtime profile
- strict replica root: `outputs/milestones/MB_20260324_globalfullreplay_strict`
- baseline full rebuild root: `outputs/milestones/MB_20260324_globalfullreplay_baseline`
- curated delivery root: `outputs/milestones/MB_20260324_globalfullreplay_delivery`
- heights: `500 km`, `750 km`, `1000 km`
- sensor group: `baseline`

## Pass-ratio semantics
- `historyFull`: true computed history points only.
- `effectiveFullRange`: effective-domain dense rebuild only.
- `globalFullReplay`: full-domain replay on the global dense `Ns` grid, with missing gaps left broken.
- `frontierZoom`: local frontier cut from the effective dense rebuild.
- default primary pass-ratio figure is `globalFullReplay`.

## Heatmap semantics
- `numeric_requirement + local`: effective/local requirement surface.
- `numeric_requirement + globalReplay`: full-frame numeric replay surface, undefined cells preserved.
- `state_map + local`: local coverage state map.
- `state_map + globalReplay`: global coverage state map aligned with the replay grid.
- default primary heatmap is numeric `globalReplay`.

## Recommended roots
- canonical baseline: `outputs/milestones/MB_20260324_globalfullreplay_baseline`
- curated delivery: `outputs/milestones/MB_20260324_globalfullreplay_delivery`
- strict replica anchor: `outputs/milestones/MB_20260324_globalfullreplay_strict`

## Key validation tables
- `passratio_source_semantics_audit_summary.csv`
- `passratio_view_scope_audit_summary.csv`
- `passratio_tail_oscillation_audit.csv`
- `heatmap_source_semantics_audit_summary.csv`
- `heatmap_view_scope_audit_summary.csv`
- `MB_full_rebuild_closure_summary.csv`
