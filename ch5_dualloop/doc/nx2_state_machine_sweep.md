# NX-2 State Machine Sweep

## Purpose

This sweep is the first quantitative check of the minimal state-machine shell introduced in NX-2 round 1.

We do not touch template guidance here.
We only scan three state-machine knobs:

- `nx2_dwell_steps`
- `nx2_guard_ttl_steps`
- `nx2_guard_enable`

## Why this sweep matters

NX-2 round 1 already connected the following fields into `trackingCK`:

- `state_series`
- `switch_applied`
- `ttl_steps`

Therefore the engineering question is no longer "is the shell connected?"
The question is now:

- does the shell suppress meaningless switching?
- does it hurt or improve worst-window custody quality?
- does it change outage behavior?

## Output metrics

Each sweep row records:

- `q_worst_window`
- `q_worst_point`
- `phi_mean`
- `outage_ratio`
- `longest_outage_steps`
- `mean_rmse`
- `max_rmse`
- `switch_count`
- `applied_switch_count`
- `mean_sat_count`

## Current intended interpretation

A useful setting should ideally:

- reduce `switch_count` or `applied_switch_count`
- keep `q_worst_window` stable or improve it
- avoid increasing `outage_ratio`
- avoid very long `longest_outage_steps`

If switch count drops but worst-window quality collapses, then the shell is over-constraining the dynamic chain.
If all metrics stay the same across the grid, then the shell is too weak to matter.
