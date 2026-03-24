# MB Refactor Target Structure

## Goal

This refactor establishes a hard split between frozen legacy MB assets and the new MB_v2 development line.

## Target Layout

```text
milestones/
  legacy/
    MB_legacy/
  active/
    MB_v2/

run_milestones/
  legacy/
    run_mb_legacy_snapshot.m
  active/
    run_mb_v2_main.m
    run_mb_v2_strict_replica.m
    run_mb_v2_scene_stats.m
    run_mb_v2_smoke.m

src/
  mb/
    legacy/
    v2/
      adapters/
      semantics/
      scene_stats/
      exports/
      plots/
  analysis/
    mb_v2/

outputs/
  milestones/
    canonical/
      MB_v2/
        baseline/
        strict/
        scene_stats/
        delivery/
    archive/
      MB_legacy/
    smoke/
      MB_legacy/

docs/
  mb_v2/
```

## Directory Roles

- `milestones/legacy/MB_legacy`: reserved marker space for frozen MB orchestration references and legacy manifests.
- `milestones/active/MB_v2`: reserved marker space for future MB_v2 milestone-facing logic.
- `run_milestones/legacy`: reproduction-only wrappers for frozen MB behavior.
- `run_milestones/active`: the only approved long-term entrypoints for new MB development.
- `src/mb/legacy`: legacy namespace policy surface; current round uses soft migration rather than physically moving the old modules.
- `src/mb/v2`: new implementation namespace for wrappers, semantics, scene statistics, exports, and plots.
- `src/analysis/mb_v2`: MB_v2-only analysis helpers.
- `outputs/milestones/canonical/MB_v2`: curated reference locations for future MB_v2 outputs.
- `outputs/milestones/archive/MB_legacy`: manifest and archive index layer for historical MB roots.
- `outputs/milestones/smoke/MB_legacy`: smoke-only historical MB provenance layer.
- `docs/mb_v2`: the single documentation home for this refactor and future MB_v2 governance.

## This Round

- The structure is created now even where implementation is not yet present.
- Legacy source modules remain physically in their current locations during this round unless a later task proves a safe move.
- Stage source files remain out of scope and unchanged.
