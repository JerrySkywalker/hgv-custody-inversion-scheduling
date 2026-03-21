# MB Search Policy

## Scope

This note describes the current Milestone B search-domain policy for `legacyDG`, `closedD`, and `comparison` runs. It does not change Stage05/06 core semantics.

## Search Domain Layers

- Initial `N_s` domain comes from `cfg.milestones.MB_semantic_compare.Ns_initial_range`.
- Expansion blocks come from `cfg.milestones.MB_semantic_compare.Ns_expand_blocks`.
- Hard upper bound comes from `cfg.milestones.MB_semantic_compare.Ns_hard_max`.
- Strict Stage05 replica keeps `Ns_allow_expand = false` and remains locked to the reference domain.

## Expansion Triggers

Expansion is attempted only when at least one diagnostic indicates the current domain is likely insufficient:

- right-side unity plateau is not reached
- feasible frontier remains too close to the current `N_s` upper bound
- minimum feasible heatmap cells are boundary-dominated
- comparison gap remains infinite because one branch is still truncated

## Expansion Stop Reasons

Current stop reasons include:

- `unity_plateau_reached`
- `frontier_internalized`
- `hard_max_reached`
- `block_budget_exhausted`
- `no_new_feasible_points`
- `comparison_gap_still_infinite_but_hardmax_hit`

These are exported into incremental search history and stop-reason tables.

## Snapshot Rule

For non-strict MB exports, the preferred source for formal outputs is `expanded_final`.

- `initial` and intermediate snapshots are diagnostic
- `expanded_final` is the default source for pass-ratio, heatmap, frontier, and comparison exports
- strict Stage05 replica remains a separate locked reference branch
