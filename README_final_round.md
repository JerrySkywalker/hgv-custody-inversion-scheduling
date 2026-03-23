# MB Final Round

This round freezes MB plotting around four explicit pass-ratio views and two explicit heatmap scopes.

## Pass-ratio views
- `historyFull`: true computed history points only; no zero padding; no gap bridging.
- `effectiveFullRange`: effective-domain dense rebuild only; not a global-domain figure.
- `globalFullReplay`: global replay on the full `Ns` grid from the original lower bound to final `Ns_max`; only defined segments are connected.
- `frontierZoom`: local frontier window derived from the effective dense rebuild.

## Heatmap scopes
- `local`: effective/local defined surface.
- `globalReplay`: full global `P-i` frame with undefined cells preserved.
- `numeric_requirement` and `state_map` remain separate matrix families.

## Recommended usage
- Main paper pass-ratio figure: `globalFullReplay`
- Effective-domain analysis figure: `effectiveFullRange`
- Historical trace / diagnostic provenance: `historyFull`
- Local transition diagnostic: `frontierZoom`
- Main paper heatmap: numeric `globalReplay`
- Supporting coverage/state heatmap: state-map `globalReplay`

## Current roots
- baseline canonical root: `outputs/milestones/MB_20260324_globalfullreplay_baseline`
- strict replica root: `outputs/milestones/MB_20260324_globalfullreplay_strict`
- delivery bundle: `outputs/milestones/MB_20260324_globalfullreplay_delivery`

## Required audits
- `passratio_source_semantics_audit_summary.csv`
- `passratio_view_scope_audit_summary.csv`
- `passratio_tail_oscillation_audit.csv`
- `heatmap_source_semantics_audit_summary.csv`
- `heatmap_view_scope_audit_summary.csv`
- `plot_domain_root_cause_audit_summary.csv`
- `MB_full_rebuild_closure_summary.csv`
