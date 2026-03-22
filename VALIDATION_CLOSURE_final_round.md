# Validation Closure Final Round

## Strict replica
- result file: `outputs/milestones/MB_20260322_finalr1_strict/tables/MB_stage05_strictReplica_validation_summary.csv`
- expected outcome remains true: `max_abs_diff_over_curve = 0`

## Baseline h=1000 final fresh
- result file: `outputs/milestones/MB_20260322_finalr1_baseline/tables/MB_comparison_summary_h1000_baseline.csv`
- snapshot stage: `expanded_final`
- legacy frontier defined count: `8`
- closedD frontier defined count: `3`
- comparison remains `diagnostic_only`

## Stage figure runtime smoke
- summary file: `outputs/milestones/STAGE_plot_runtime_smoke_20260322_finalr1_stage/tables/STAGE_headless_smoke_summary.csv`
- `stage01_scenario_disk`: headless export passes
- `stage09_inverse_plot`: still does not pass in this workspace / batch context and must not be reported as passed

## Final closure table
- `outputs/milestones/MB_20260322_finalr1_baseline/tables/MB_validation_closure_round_final.csv`
