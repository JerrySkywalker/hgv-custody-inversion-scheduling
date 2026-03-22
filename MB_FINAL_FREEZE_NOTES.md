# MB Final Freeze Notes

## Recommended configurations
- main paper figures: baseline `h=1000`, default expandable profile, `fullRange` first and `frontierZoom` second
- appendix / diagnostic: heavy profile, comparison chain, state maps, refinement and overcompute summaries
- strict validation: `strict_stage05_replica` only

## Figure selection rule
- `fullRange`: show the entire searched trend from the configured lower bound through the final expanded domain
- `frontierZoom`: show only the local transition / frontier neighborhood and never replace `fullRange`

## Heavy profile usage
- use heavy only when default profile still leaves frontier coverage weak or right plateau incomplete
- heavy is supplemental; it does not replace the default baseline fresh chain in the final package

## Modules that should now stay stable
- `startup.m`
- `project_path_manager.m`
- `project_figure_manager.m`
- MB cache/signature helpers
- MB export naming and `fullRange` / `frontierZoom` wiring

## Known limits
- baseline `h=1000` comparison remains diagnostic-only
- some Stage smoke cases still depend on unavailable upstream cache in the current workspace
