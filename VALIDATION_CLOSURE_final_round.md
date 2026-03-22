# Validation Closure Final Round

## Strict replica
- result file: `outputs/milestones/MB_20260322_finalr3_strict/tables/MB_stage05_strictReplica_validation_summary.csv`
- expected outcome remains true:
  - `max_abs_diff_over_curve = 0`
  - `max_abs_diff = 0`

## Startup / runtime
- startup timing file: `outputs/milestones/startup_audit/tables/startup_timing_before_after.csv`
- current reuse result:
  - `full_refresh = 0.5621355 s`
  - `same_session_reuse = 0 s`
- runtime summary file: `outputs/milestones/startup_audit/tables/runtime_mode_summary.csv`

## Baseline h=1000 final fresh
- result file: `outputs/milestones/MB_20260322_finalr3_baseline/tables/MB_comparison_summary_h1000_baseline.csv`
- snapshot stage: `expanded_final`
- profile: `mb_default / expand_default`
- legacy frontier defined count: `8`
- closedD frontier defined count: `3`
- comparison remains `diagnostic_only`
- right plateau remains incomplete on both semantic branches:
  - `right_plateau_reached_legacy = 0`
  - `right_plateau_reached_closed = 0`

## New figure semantics
- pass-ratio:
  - `historyFull`: original search-history lower bound through current max
  - `effectiveFullRange`: final effective expanded domain
  - `frontierZoom`: local frontier neighborhood only
- heatmap:
  - `local`: refined / overcomputed defined surface
  - `globalSkeleton`: global P-i frame with undefined cells preserved

## Stage figure runtime smoke
- summary file: `outputs/milestones/STAGE_plot_runtime_smoke_20260322_finalr3_stage/tables/STAGE_headless_smoke_summary.csv`
- `stage01_scenario_disk`: headless and visible export both pass
- `stage09_inverse_plot`: still does not pass in this workspace because upstream `Stage08.5` cache is missing
- interpretation:
  - plot runtime mechanism is wired in
  - the stage09 business chain is not marked as passed

## Final closure table
- `outputs/milestones/MB_20260322_finalr3_baseline/tables/MB_validation_closure_round_final.csv`
- current closure flags additionally confirm:
  - `full_history_export_pass = 1`
  - `heatmap_state_map_separation_pass = 1`
  - `output_organization_pass = 1`
