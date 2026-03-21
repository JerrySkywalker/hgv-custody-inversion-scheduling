# MB Cache Policy

## Goal

MB cache reuse is split into semantic cache reuse and figure/export reruns so plotting-only changes do not trigger expensive search recomputation.

## Semantic Cache Signature

The semantic cache signature includes at least:

- semantic mode
- family set
- height
- sensor group and propagated sensor parameters
- search profile name and mode
- `N_s` initial range
- `N_s` expansion blocks
- `N_s` hard max
- `P` grid
- `T` grid
- evaluator version
- sensor propagation version

The current implementation is centered on:

- `build_mb_semantic_cache_signature`
- `build_mb_cache_signature`
- `build_mb_cache_manifest`
- `is_mb_cache_compatible`

## Figure Signature

Figure/export signature is separate and may change without invalidating semantic search:

- figure style mode
- diagnostic vs paper-ready export
- plot-domain mode
- headless vs visible plotting
- export-only annotation/layout settings

## Version Tags

Manual version tags are available through:

- `cfg.milestones.MB_semantic_compare.cache_profile.semantic_version`
- `cfg.milestones.MB_semantic_compare.cache_profile.figure_version`

Bump the semantic version when feasibility, pass-ratio, or propagated sensor semantics change.
Bump the figure version when export-only conventions change.

## Reuse Rules

Safe semantic cache reuse:

- annotation-only changes
- plot-domain label changes
- paper-ready guardrail changes
- headless vs visible export changes

Semantic cache invalidation:

- `N_s` hard max changes
- expansion block changes
- `P/T` grid changes
- sensor propagation changes
- semantic evaluator changes
