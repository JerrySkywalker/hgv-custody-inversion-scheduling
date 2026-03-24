# Codex MB_v2 Development Policy

## Single Active Development Surface

All future MB feature work must go only to:

- `milestones/active/MB_v2`
- `run_milestones/active`
- `src/mb/v2`
- `src/analysis/mb_v2`
- `docs/mb_v2`

## Legacy Freeze Rule

- Do not add new features to legacy MB milestone logic.
- Do not add new features to legacy MB runners under `run_stages` or old `run_milestones` entrypoints.
- Do not add new features to legacy MB source under `src/mb/closedd`, `src/mb/compare`, `src/mb/legacydg`, `src/mb/vgeom`, or the MB-only legacy helpers in `src/analysis`.

## Stage Protection Rule

- Do not modify the original Stage source files.
- If MB_v2 needs Stage05/06 behavior, it must reuse them only through adapter or wrapper code under `src/mb/v2/adapters`.
- MB_v2 must not copy Stage05/06 source into a new implementation tree.

## Output Writing Rule

- New formal MB outputs may write only to `outputs/milestones/canonical/MB_v2`.
- New MB smoke outputs may write only to `outputs/milestones/smoke/MB_v2`.
- Do not write new formal outputs into the legacy `outputs/milestones/MB` root or any historical MB root.

## Codex Working Rule

- When extending MB, start from `run_milestones/active/run_mb_v2_main.m`.
- Add strict-reference work through `run_milestones/active/run_mb_v2_strict_replica.m`.
- Add scene-statistics work through `run_milestones/active/run_mb_v2_scene_stats.m`.
- Add lightweight validation through `run_milestones/active/run_mb_v2_smoke.m`.
