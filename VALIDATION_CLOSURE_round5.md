# MB Round5 Validation Closure

## Strict replica

- strict Stage05 replica was re-run after the plotting/export changes
- no Stage05/06 core files were modified
- expected validation target remains:
  - `max_abs_diff_over_curve = 0`

## Heavy fresh baseline `h=1000`

Profile:

- search profile: `mb_heavy`
- profile mode: `expand_heavy`
- sensor group: `baseline`
- family: `nominal`

Observed summary:

- `legacyDG final_ns_search_max = 600`
- `closedD final_ns_search_max = 600`
- `legacyDG expansion_iterations = 3`
- `closedD expansion_iterations = 3`
- both stopped with `hard_upper_bound_reached`
- `legacyDG frontier_defined_count = 7 / 10`
- `closedD frontier_defined_count = 6 / 10`
- `frontier_delta_defined_count = 5`
- `legacyDG final pass ratio = 1.0`
- `closedD final pass ratio = 0.9167`

Interpretation:

- heavy expansion clearly improved closedD frontier coverage relative to the previous weak run
- heavy expansion also reduced the earlier “almost single-point frontier” problem
- however, the comparison is still not fully paper-ready because the right plateau is still not cleanly reached

## Heatmap overcompute / frontier refinement

- bounded overcompute was active only near sparse/right-edge frontier regions
- frontier refinement was applied locally near weak frontier regions instead of globally densifying the grid
- the refined outputs are exported with provenance tables and should not be confused with the original coarse grid

## Stage plotting runtime smoke

Verified:

- `stage01_scenario_disk` headless: pass
- `stage01_scenario_disk` visible: pass

Explicit exception:

- `stage09_inverse_plot` could not complete the smoke test because the required upstream Stage08.5 cache was absent in the current stage output tree
- this is recorded in `STAGE_headless_smoke_summary.csv`; it was not silently treated as a pass
