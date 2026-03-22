# MB Cache Policy Final Round

## Semantic cache signature
Semantic cache reuse depends on the MB semantic signature, which includes:
- semantic mode / algorithm family
- sensor group
- height set and family set
- searchable domain:
  - `Ns_initial_range`
  - expand blocks / expand policy
  - hard max
  - P / T / inclination grids
- relevant schema / version tags
- any threshold or rule that changes feasibility, pass-ratio, frontier, or gap values

## Figure / export changes that do not force semantic recompute
The following should reuse semantic cache:
- switching `historyFull` / `effectiveFullRange` / `frontierZoom`
- switching `local` / `globalSkeleton` heatmap views
- changing plot labels, short tags, metadata sidecars, or delivery packaging
- changing headless / visible runtime behavior
- changing paper-ready guardrail or export-only logic
- regenerating `MB_output_inventory.csv`, `MB_output_recommended_roots.csv`, or `MB_historical_output_map.csv`

## Changes that must invalidate semantic cache
The following must trigger semantic recompute:
- changing searchable domain or expansion policy
- changing `Ns_hard_max`
- changing P / T / inclination grids
- changing semantic evaluator logic
- changing sensor-group propagation logic
- changing schema / version tags for semantic artifacts

## Runtime notes
- headless figure mode is runtime-only and must not invalidate semantic cache
- plot-only reruns are expected to rebuild figures and sidecars while reusing semantic tables
- strict replica remains isolated and must not share cache namespace with baseline / optimistic / robust semantic runs
