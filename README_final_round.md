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
- strict replica fresh root: `outputs/milestones/MB_20260322_finalr2_strict`
- baseline fresh root: `outputs/milestones/MB_20260322_finalr2_baseline`
- stage smoke root: `outputs/milestones/STAGE_plot_runtime_smoke_20260322_finalr2_stage`
- delivery bundle: `outputs/milestones/MB_final_round_delivery`

## Paper vs diagnostic
- primary paper-candidate pass-ratio figures should prefer `historyFull` first and `effectiveFullRange` second
- `frontierZoom` is supplemental and must not replace the global trend figure
- `globalSkeleton` heatmaps are the global reference view; `local` heatmaps are the refined defined-surface view
- baseline `h=1000` comparison remains `diagnostic_only`

## Guarantees
- Stage05/06 original core files were not modified
- strict replica still matches the Stage05 reference with zero curve difference
- plot-only / export-only changes remain separated from semantic cache invalidation
