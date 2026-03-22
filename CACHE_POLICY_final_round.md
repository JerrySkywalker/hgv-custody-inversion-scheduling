# Cache Policy Final Round

## Semantic cache
Semantic cache reuse is keyed by search semantics rather than figure styling.

Included factors:
- semantic mode
- sensor group
- search profile name and mode
- searchable `N_s / P / T / i` domain
- expansion blocks and hard max
- schema / version tags

## Plot-only changes
These should not force semantic recompute:
- `fullRange` vs `frontierZoom` export choice
- short on-figure tags
- paper-ready guardrail messaging
- headless vs visible figure mode

## Semantic changes
These must invalidate semantic cache:
- searchable domain changes
- expansion policy changes
- hard max changes
- feasibility / frontier / pass-ratio logic changes

## Final-round expectation
- plot-only reruns should reuse semantic cache
- search-domain changes should trigger recompute
