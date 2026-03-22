# MB Round5 Paper Figure Shortlist

## Tier A: main candidates

- baseline `h=1000` legacyDG `global_trend` pass-ratio
- baseline `h=1000` closedD `global_trend` pass-ratio
- baseline `h=1000` comparison `global_trend` overlay
- baseline `h=1000` legacyDG/closedD minimum-`N_s` heatmaps using the expanded-final snapshot

## Tier B: supporting figures

- baseline `h=1000` comparison `frontier_zoom` overlay
- baseline `h=1000` closedD frontier summary after heavy refinement
- cross-profile `legacyDG` pass-ratio overlay
- cross-profile `closedD` pass-ratio overlay

## Tier C: diagnostic only

- any frontier shift figure that still depends on weak or partially saturated closedD coverage
- any comparison figure whose sidecar indicates plateau-not-reached
- any sparse heatmap dominated by boundary-suspect states

## Current recommendation

Use the new `global_trend` figures as the primary discussion figures.

Use `frontier_zoom` only as a local-detail companion figure.

Do not use the heavy `h=1000` comparison as a final paper-ready figure without an explicit note that the right plateau is still incomplete under the current heavy search budget.
