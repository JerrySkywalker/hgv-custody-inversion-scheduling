# Framework Migration Map

Last updated: 2026-03-27

## Migration Principles

1. Do not modify `legacy/`.
2. Migrate into final `framework/` directories directly.
3. Do not introduce `ported/`, `stageXX`, or `milestone` names inside `framework/`.
4. Keep `stageXX` names only in `experiments/chapter4/static_parity/` runners.
5. Migrate stage-by-stage in dependency order:
   - Stage00
   - Stage01
   - Stage02
   - Stage03
   - Stage04
   - Stage05
   - Stage09
6. For Stage02–05 and Stage09, prefer:
   - copy legacy kernel files
   - rename to final framework names immediately
   - adjust function headers and internal calls
   - wrap with parity runners in `experiments/`

---

## Stage00

### Scope
- startup
- framework defaults
- run config
- output paths
- runtime manifest

### Legacy Source
- `legacy/startup.m`
- `legacy/src/common/configure_stage_output_paths.m`
- related common path/output helpers

### Framework Target
- `startup.m`
- `startup_framework.m`
- `startup_legacy.m`
- `framework/config/`
- `framework/core/`
- `experiments/chapter4/static_parity/run_stage00_parity.m`

### Strategy
- New implementation first
- Keep legacy optional via startup mode
- Do not copy stage script logic directly

### Current Status
- DONE (initial)
- startup split into framework-only / with-legacy modes
- Stage00 parity runner exists
- defaults / cfg / paths / manifest chain exists

### Remaining Gaps
- later may add migration notes into manifest
- no urgent blocker

### Smoke Test
- `startup_framework('force_reinit', true);`
- `out = run_stage00_parity();`

---

## Stage01

### Scope
- case source organization
- nominal / heading / critical generation
- registry
- task set
- legacy-compatible casebank view

### Legacy Source
- `legacy/src/scenario/build_casebank_stage01.m`
- `legacy/src/scenario/generate_nominal_entry_family.m`
- `legacy/src/scenario/generate_heading_family.m`
- `legacy/src/scenario/generate_critical_family.m`

### Framework Target
- `framework/sources/`
- `framework/casebank/`
- `framework/scenario/build_stage01_casebank_view.m`
- `experiments/chapter4/static_parity/run_stage01_parity.m`

### Strategy
- Framework-native rewrite, informed by legacy
- Keep internal schema stronger than legacy
- Add legacy-compatible casebank view

### Current Status
- DONE (functional)
- nominal / heading / critical generators exist
- registry exists
- task set selection exists
- casebank view exists
- full Stage01 parity runner exists

### Remaining Gaps
- legacy-style case naming alignment in view
- source bank / source-object management
- geodetic / ENU / ECEF / ECI field alignment
- stage01 metadata alignment

### Smoke Test
- `startup_framework('force_reinit', true);`
- `out = run_stage01_parity();`
- full profile: nominal + heading + critical

---

## Stage02

### Scope
- HGV dynamics
- control profile
- event handling
- atmosphere
- per-track propagation
- trajectory set summary

### Legacy Source
- `legacy/src/target/build_hgv_cfg_from_case_stage02.m`
- `legacy/src/target/make_ctrl_profile_stage02.m`
- `legacy/src/target/hgv_vtc_dynamics.m`
- `legacy/src/target/events_hgv_stage02.m`
- `legacy/src/target/atmosphere_us76.m`
- `legacy/src/target/propagate_hgv_case_stage02.m`
- `legacy/src/target/summarize_hgv_case_stage02.m`
- `legacy/src/target/summarize_trajbank_stage02.m`
- `legacy/src/target/validate_hgv_trajectory_stage02.m`
- `legacy/src/target/geodetic_to_local_xy_stage02.m`
- `legacy/src/target/local_xy_to_geodetic_stage02.m`
- required `legacy/src/geo/*`

### Framework Target
- `framework/dynamics/`
- `framework/dynamics/geo/`
- `experiments/chapter4/static_parity/run_stage02_parity.m`

### Rename Map
- `build_hgv_cfg_from_case_stage02.m` -> `build_dynamics_init_from_case.m`
- `make_ctrl_profile_stage02.m` -> `build_control_profile.m`
- `events_hgv_stage02.m` -> `hgv_events.m`
- `propagate_hgv_case_stage02.m` -> `propagate_single_track.m`
- `summarize_hgv_case_stage02.m` -> `summarize_single_trajectory.m`
- `summarize_trajbank_stage02.m` -> `summarize_trajectory_set.m`
- `validate_hgv_trajectory_stage02.m` -> `validate_trajectory.m`
- `geodetic_to_local_xy_stage02.m` -> `geodetic_to_local_xy.m`
- `local_xy_to_geodetic_stage02.m` -> `local_xy_to_geodetic.m`

### Strategy
- Copy legacy kernel files directly into final framework location
- Rename immediately
- Adjust function names and direct dependencies
- Wrap with stage runner

### Current Status
- NOT STARTED

### Smoke Target
- propagate nominal-only task set from Stage01
- output trajectory set and summary

---

## Stage03

### Scope
- single-layer walker
- constellation propagation
- LOS geometry
- visibility matrix
- target ECI history
- visibility summaries

### Legacy Source
- `legacy/src/constellation/build_single_layer_walker_stage03.m`
- `legacy/src/constellation/propagate_constellation_stage03.m`
- `legacy/src/sensing/compute_los_geometry_stage03.m`
- `legacy/src/sensing/compute_visibility_matrix_stage03.m`
- `legacy/src/sensing/is_visible_stage03.m`
- `legacy/src/sensing/eci_from_stage02_target_stage03.m`
- `legacy/src/sensing/summarize_visibility_case_stage03.m`
- `legacy/src/sensing/summarize_visibility_bank_stage03.m`

### Framework Target
- `framework/constellation/`
- `framework/visibility/`
- `experiments/chapter4/static_parity/run_stage03_parity.m`

### Rename Map
- `build_single_layer_walker_stage03.m` -> `build_single_layer_walker.m`
- `propagate_constellation_stage03.m` -> `propagate_constellation.m`
- `compute_los_geometry_stage03.m` -> `compute_line_of_sight_geometry.m`
- `compute_visibility_matrix_stage03.m` -> `compute_visibility_matrix.m`
- `is_visible_stage03.m` -> `is_visible.m`
- `eci_from_stage02_target_stage03.m` -> `build_target_eci_history.m`
- `summarize_visibility_case_stage03.m` -> `summarize_visibility_case.m`
- `summarize_visibility_bank_stage03.m` -> `summarize_visibility_set.m`

### Strategy
- Copy kernel files
- Rename immediately
- Connect to Stage02 trajectory set

### Current Status
- NOT STARTED

### Smoke Target
- one small walker grid + small trajectory set
- visibility set summary

---

## Stage04

### Scope
- time info series
- window grid
- info accumulation
- worst window scan
- gamma requirement

### Legacy Source
- `legacy/src/window/build_time_info_series_stage04.m`
- `legacy/src/window/build_window_grid_stage04.m`
- `legacy/src/window/build_window_info_matrix_stage04.m`
- `legacy/src/window/accumulate_visible_info_matrix_stage04.m`
- `legacy/src/window/evaluate_window_margin_stage04.m`
- `legacy/src/window/scan_worst_window_stage04.m`
- `legacy/src/window/calibrate_gamma_req_stage04.m`
- `legacy/src/window/summarize_window_case_stage04.m`
- `legacy/src/window/summarize_window_bank_stage04.m`
- `legacy/src/window/summarize_window_margin_bank_stage04.m`

### Framework Target
- `framework/window/`
- `experiments/chapter4/static_parity/run_stage04_parity.m`

### Rename Map
- `build_time_info_series_stage04.m` -> `build_time_info_series.m`
- `build_window_grid_stage04.m` -> `build_window_grid.m`
- `build_window_info_matrix_stage04.m` -> `build_window_info_matrix.m`
- `accumulate_visible_info_matrix_stage04.m` -> `accumulate_visible_info_matrix.m`
- `evaluate_window_margin_stage04.m` -> `evaluate_window_margin.m`
- `scan_worst_window_stage04.m` -> `scan_worst_window.m`
- `calibrate_gamma_req_stage04.m` -> `calibrate_gamma_requirement.m`
- `summarize_window_case_stage04.m` -> `summarize_window_case.m`
- `summarize_window_bank_stage04.m` -> `summarize_window_set.m`
- `summarize_window_margin_bank_stage04.m` -> `summarize_window_margin_set.m`

### Strategy
- Copy kernel files
- Rename immediately
- Connect to Stage03 visibility set

### Current Status
- NOT STARTED

### Smoke Target
- one small visibility set
- gamma requirement and worst-window summary

---

## Stage05

### Scope
- search grid
- single-layer design evaluation
- search summaries

### Legacy Source
- `legacy/src/search/build_stage05_search_grid.m`
- `legacy/src/search/evaluate_single_layer_walker_stage05.m`
- `legacy/src/search/summarize_stage05_grid.m`

### Framework Target
- `framework/search/`
- `experiments/chapter4/static_parity/run_stage05_parity.m`

### Rename Map
- `build_stage05_search_grid.m` -> `build_search_grid.m`
- `evaluate_single_layer_walker_stage05.m` -> `evaluate_single_layer_design.m`
- `summarize_stage05_grid.m` -> `summarize_search_grid.m`

### Strategy
- Copy kernel files
- Rename immediately
- Use Stage04 outputs as context

### Current Status
- NOT STARTED

### Smoke Target
- small design grid
- search summary table

---

## Stage09

### Scope
- inverse evaluation context
- projected accuracy
- window metrics
- single-layer inverse design evaluation
- minimum boundary extraction

### Legacy Source
- `legacy/src/search/build_stage09_eval_context.m`
- `legacy/src/search/evaluate_single_layer_walker_stage09.m`
- `legacy/src/search/extract_stage09_minimum_boundary.m`
- `legacy/src/search/summarize_stage09_grid.m`
- `legacy/src/window/compute_projected_accuracy_stage09.m`
- `legacy/src/window/compute_window_metrics_stage09.m`
- `legacy/src/common/build_stage09_casebank.m`

### Framework Target
- `framework/search/`
- `framework/window/`
- `experiments/chapter4/static_parity/run_stage09_parity.m`

### Rename Map
- `build_stage09_eval_context.m` -> `build_inverse_eval_context.m`
- `evaluate_single_layer_walker_stage09.m` -> `evaluate_single_layer_inverse_design.m`
- `extract_stage09_minimum_boundary.m` -> `extract_minimum_boundary.m`
- `summarize_stage09_grid.m` -> `summarize_inverse_design_grid.m`
- `compute_projected_accuracy_stage09.m` -> `compute_projected_accuracy.m`
- `compute_window_metrics_stage09.m` -> `compute_window_metrics.m`
- `build_stage09_casebank.m` -> `build_inverse_casebank.m`

### Strategy
- Copy kernel files
- Rename immediately
- Connect after Stage04/05 pipeline is available

### Current Status
- NOT STARTED

### Smoke Target
- small inverse eval context
- minimum boundary extraction

---

## Execution Order

1. Stage00 status freeze
2. Stage01 status freeze
3. Stage02 migrate + smoke
4. Stage03 migrate + smoke
5. Stage04 migrate + smoke
6. Stage05 migrate + smoke
7. Stage09 migrate + smoke

---

## Notes

- Do not rename internal registry `traj_id` to legacy-style case IDs.
- Legacy-style naming should exist in Stage01 `casebank_view` only.
- Geodetic / ENU / ECEF / ECI alignment should be handled in Stage01 payload/view and then consumed by Stage02.
- `framework/` must remain free of `stageXX` and `milestone` names.
- `experiments/` is allowed to keep `run_stageXX_parity.m`.
