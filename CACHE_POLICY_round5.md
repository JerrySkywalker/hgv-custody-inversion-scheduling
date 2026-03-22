# MB Round5 Cache Policy

## Semantic cache signature

Semantic cache reuse is keyed by the combination of:

- semantic mode
- sensor group
- height / family context
- `N_s` search domain
- `P/T/i` search grid
- expandable search policy
- hard max
- cache schema / version tag

## Figure/export reruns

The following changes should *not* force semantic recomputation:

- figure visibility mode (`headless` / `visible`)
- annotation wording
- paper-ready guardrail wording
- global-trend vs frontier-zoom plotting choice
- discrete heatmap rendering choice

These should force semantic recomputation:

- `N_s` hard max changes
- expandable block changes
- search-grid changes
- semantic evaluator changes
- sensor propagation changes

## Round5 note

This round added more plotting variants (`global_trend`, `frontier_zoom`, state-aware heatmaps) without changing the underlying semantic solver definition. Those plotting changes are intended to remain figure-layer changes, not semantic-cache invalidators.
