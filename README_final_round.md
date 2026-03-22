# MB Final Round

This package is the final MB closure handoff for the MATLAB project.

## What is frozen
- startup/path now uses whitelist initialization with session reuse
- figure runtime is unified through the project figure manager
- pass-ratio exports are now split into three explicit views:
  - `historyFull`: starts from the original initial search-domain lower bound
  - `effectiveFullRange`: spans the final expanded effective search domain
  - `frontierZoom`: focuses on the local transition / frontier neighborhood
- heatmap exports are now split into two explicit surfaces:
  - `local`: current defined surface after refinement / overcompute
  - `globalSkeleton`: full global P-i frame with undefined cells preserved
- expanded search, heatmap overcompute, and frontier refinement remain integrated into the MB export chain
- strict Stage05 replica remains the validation anchor

## Final-round roots
- strict replica fresh root: `outputs/milestones/MB_20260322_finalr3_strict`
- baseline fresh root: `outputs/milestones/MB_20260322_finalr3_baseline`
- stage smoke root: `outputs/milestones/STAGE_plot_runtime_smoke_20260322_finalr3_stage`
- delivery bundle: `outputs/milestones/MB_final_round_delivery`
- canonical root manifest: `outputs/milestones/MB_final_round_delivery/MB_output_recommended_roots.csv`
- inventory/index:
  - `outputs/milestones/MB_final_round_delivery/MB_output_inventory.csv`
  - `outputs/milestones/MB_final_round_delivery/MB_historical_output_map.csv`
  - `outputs/milestones/MB_final_round_delivery/MB_recommended_figure_index.csv`
- canonical copies:
  - `outputs/milestones/MB_final_round_delivery/canonical_figures`
  - `outputs/milestones/MB_final_round_delivery/canonical_tables`

## Audit tables
- plot-domain audit:
  - `outputs/milestones/MB_20260322_finalr3_baseline/tables/passratio_plot_domain_audit_summary.csv`
- heatmap render-mode audit:
  - `outputs/milestones/MB_20260322_finalr3_baseline/tables/heatmap_render_mode_audit_summary.csv`
- semantic-domain consistency audit:
  - `outputs/milestones/MB_20260322_finalr3_baseline/tables/semantic_domain_consistency_summary.csv`
- temp script audit / cleanup:
  - `outputs/milestones/startup_audit/tables/temp_script_audit_summary.csv`
  - `outputs/milestones/startup_audit/tables/temp_script_cleanup_summary.csv`

## Paper vs diagnostic
- primary paper-candidate pass-ratio figures should prefer `historyFull` first and `effectiveFullRange` second
- `frontierZoom` is supplemental and must not replace the global trend figure
- `globalSkeleton` heatmaps are the global reference view; `local` heatmaps are the refined defined-surface view
- baseline `h=1000` comparison remains `diagnostic_only`

## Guarantees
- Stage05/06 original core files were not modified
- strict replica still matches the Stage05 reference with zero curve difference
- plot-only / export-only changes remain separated from semantic cache invalidation
- `historyFull` / `effectiveFullRange` / `frontierZoom` now have explicit metadata sidecars with domain-origin fields
- root `temp_*.m` scripts were removed from the repository root and conservatively archived under `sandbox/temp_scripts_archive/mb_final_round/`
