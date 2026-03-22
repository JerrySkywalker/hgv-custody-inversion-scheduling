# MB Final Freeze Notes

## Recommended configurations
- main paper trend figures:
  - baseline `h=1000`
  - default expandable profile
  - prefer `historyFull` first and `effectiveFullRange` second
- appendix / diagnostic:
  - `frontierZoom`
  - state maps
  - comparison frontier shift
  - heatmap provenance / overcompute / refinement summaries
- strict validation:
  - `strict_stage05_replica` only

## Figure semantics that should now stay fixed
- `historyFull`
  - original search-history lower bound to current max
- `effectiveFullRange`
  - final effective expanded domain only
- `frontierZoom`
  - local frontier / platform-formation neighborhood only
- `local` heatmap
  - refined / overcomputed defined surface
- `globalSkeleton` heatmap
  - full global coordinate frame with undefined regions kept visible

## Heavy profile usage
- use heavy only when default profile still leaves frontier coverage weak or right plateau incomplete
- heavy is supplemental; it does not replace the default baseline fresh chain in the final package

## Modules that should now stay stable
- `startup.m`
- `project_path_manager.m`
- `project_figure_manager.m`
- MB cache/signature helpers
- MB pass-ratio view naming and export wiring
- MB heatmap local/globalSkeleton export wiring

## Known limits
- baseline `h=1000` comparison remains diagnostic-only
- `closedD` frontier coverage at baseline `h=1000` is still weak relative to legacyDG
- `stage09_inverse_plot` smoke remains blocked by missing upstream `Stage08.5` cache in this workspace
- Stage05/06 original core files remain untouched and should continue to stay frozen

## Canonical lookup files
- recommended roots: `outputs/milestones/MB_final_round_delivery/MB_output_recommended_roots.csv`
- copied artifact inventory: `outputs/milestones/MB_final_round_delivery/MB_output_inventory.csv`
- historical root index: `outputs/milestones/MB_final_round_delivery/MB_historical_output_map.csv`
