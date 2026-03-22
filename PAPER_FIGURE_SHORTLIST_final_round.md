# Paper Figure Shortlist Final Round

## Main-text candidates
- `MB_legacyDG_passratio_historyFull_h1000_baseline.png`
  - use as the primary global trend figure for legacyDG
- `MB_closedD_passratio_historyFull_h1000_baseline.png`
  - use as the primary global trend figure for closedD
- `MB_comparison_passratio_overlay_historyFull_h1000_baseline.png`
  - keep as a diagnostic-aware comparison reference; not fully paper-ready
- `MB_legacyDG_minimumNs_heatmap_globalSkeleton_h1000_baseline.png`
  - global heatmap skeleton candidate
- `MB_closedD_minimumNs_heatmap_globalSkeleton_h1000_baseline.png`
  - global heatmap skeleton candidate

## Supplemental / appendix candidates
- `MB_legacyDG_passratio_effectiveFullRange_h1000_baseline.png`
- `MB_closedD_passratio_effectiveFullRange_h1000_baseline.png`
- `MB_comparison_passratio_overlay_effectiveFullRange_h1000_baseline.png`
- `MB_legacyDG_passratio_frontierZoom_h1000_baseline.png`
- `MB_closedD_passratio_frontierZoom_h1000_baseline.png`
- `MB_comparison_passratio_overlay_frontierZoom_h1000_baseline.png`
- `MB_legacyDG_heatmap_stateMap_globalSkeleton_h1000_baseline.png`
- `MB_closedD_heatmap_stateMap_globalSkeleton_h1000_baseline.png`
- `MB_comparison_frontier_shift_h1000_baseline.png`

## Diagnostic-only
- baseline `h=1000` comparison remains diagnostic-only because:
  - `right_plateau_reached_legacy = 0`
  - `right_plateau_reached_closed = 0`
  - `closedD frontier_defined_count = 3`
- any frontier view with single-point or weak coverage should stay diagnostic-only

## Usage rule
- `historyFull` is the preferred global figure when the paper needs the full evolution from the original search-domain lower bound
- `effectiveFullRange` is the effective-domain companion figure
- `frontierZoom` is supplemental and must not replace the global trend figure
- `globalSkeleton` numeric heatmaps show minimum feasible `N_s` in the full P-i frame
- `globalSkeleton` state maps show coverage status only; they are explanatory companions, not substitutes for numeric requirement heatmaps
- recommended figure/root lookup is centralized in:
  - `outputs/milestones/MB_final_round_delivery/MB_recommended_figure_index.csv`
  - `outputs/milestones/MB_final_round_delivery/MB_output_recommended_roots.csv`
  - `outputs/milestones/MB_final_round_delivery/canonical_figures`

## Canonical audited baseline root
- `outputs/milestones/MB_20260322_plotdomain_finalfix`
  - this root contains the corrected `historyFull / effectiveFullRange / frontierZoom` exports and the final plot-domain audit tables
