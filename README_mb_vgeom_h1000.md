# MB V-Geometry Ensemble (`h = 1000 km`)

This add-on experiment lives under the MB thread and does not introduce a new Stage number.

## Scope

- Height is fixed at `h = 1000 km`
- Sensor group is fixed at `baseline`
- Semantics are fixed at `closedD` and `legacyDG`
- Inclinations are sampled at `i = [50, 60, 70, 80] deg`
- `N_s` is selected from the existing MB frontier neighborhood

## What It Reuses

- Existing MB `design_table` / design pool from the latest baseline semantic compare summary
- Existing semantic evaluation kernels
- Existing baseline products as the source of frontier-centered `N_s` lists

It does **not** rerun design search for every geometry scene.

## Scene Model

Each geometry scene is parameterized by:

- `raan_offset_deg = ΔΩ`
- `phase_offset_norm = Δφ`

For a candidate design with `P` orbital planes, the RAAN scan uses the Walker fundamental domain:

- `ΔΩ in [0, 360 / P)`

The phase offset uses a periodic scan on:

- `Δφ in [0, 1)`

## Evaluation Flow

For each case `(h=1000, i, N_s, semantic)`:

1. Load the existing design pool.
2. For each design, build the scene grid on its own Walker fundamental domain.
3. Apply `(ΔΩ, Δφ)` as whole-constellation offsets without changing relative design structure.
4. Re-evaluate pass ratio on each scene.
5. Take the best design inside each scene.
6. Aggregate scene-best statistics across scenes.
7. Build `q25` / median / mean envelopes along `N_s`.

## Main Outputs

- `MB_vgeom_scene_design_eval_table.csv`
- `MB_vgeom_scene_best_table.csv`
- `MB_vgeom_scene_agg_table.csv`
- `MB_vgeom_case_manifest.csv`
- `MB_vgeom_case_audit.csv`
- `MB_vgeom_closure_summary.csv`
- `MB_vgeom_summary.md`

Figures:

- `sceneCloud`
- `sceneMedian`
- `sceneQ25`
- `sceneQ25Envelope`

## Recommended Interpretation

- `sceneCloud` keeps the raw geometry sensitivity visible.
- `sceneMedian` shows the typical scene-best level.
- `sceneQ25` is the conservative geometry-ensemble capability curve.
- `sceneQ25Envelope` is the preferred stability-oriented boundary candidate for this add-on experiment.
