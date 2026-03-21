# MB Validation Summary Round 4

## Completed Closure Checks

- strict Stage05 replica validation remains exact
- baseline `h=1000` comparison runs on `expanded_final`
- cache A/B validation distinguishes plotting-only reruns from semantic-domain changes
- MB and Stage headless smoke tests run without requiring interactive figure windows
- frontier coverage and gap reliability tables are exported for fresh-root closure bundles

## Diagnostic-Only Cases

The following classes still require diagnostic-only handling instead of paper-ready promotion:

- weakly defined closedD frontier at `h=1000`
- comparison overlays without stable right-side unity plateau
- any export marked boundary-dominated or upper-bound insufficient in sidecar metadata

## Remaining Interpretation Caution

`expanded_final` improves consistency across pass-ratio, heatmap, frontier, and comparison outputs, but it does not guarantee all scenarios are saturated. Always check:

- `snapshot_stage`
- frontier coverage report
- gap reliability report
- export grade tables
