# MB Round5 Delivery

This round focused on result closure rather than architecture changes.

## What changed

- baseline `h=1000` heavy-profile fresh validation was run with expandable search up to `N_s=600`
- heatmap rendering was upgraded to a sparse/state-aware mode for weakly defined domains
- pass-ratio exports now emit both `global_trend` and `frontier_zoom`
- explicit Stage plotting smoke tests were added for `headless` and `visible` runtime modes
- local frontier refinement and bounded heatmap overcompute continue to feed the `expanded_final` snapshot

## Key result headline

- baseline `h=1000` `closedD` frontier coverage improved from the earlier weak regime (`3/9`) to a materially better heavy-run regime (`6/10`)
- baseline `h=1000` `legacyDG` heavy-run frontier coverage reached `7/10`
- comparison remains `diagnostic_only` because the right plateau is still not fully saturated under the current heavy run

## Most relevant output roots

- `outputs/milestones/MB`
- `outputs/milestones/STAGE_plot_runtime_smoke_20260322_stage_smoke_r3`

## Important caveat

The heavy baseline run is substantially stronger than the default profile, but it still stopped at the configured hard max (`600`) without a clean right-side unity plateau for both semantics. That means these comparison figures are more trustworthy than before, but they are still not the final paper-ready endpoint.
