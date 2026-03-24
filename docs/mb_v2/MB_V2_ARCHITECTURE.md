# MB_v2 Architecture

## Intent

MB_v2 is the only future MB development line. This round creates the directory layout, entrypoints, and interface contracts without migrating the full legacy algorithm stack.

## Layering

- `run_milestones/active`: user-facing MB_v2 entrypoints.
- `src/mb/v2/adapters`: the only place allowed to wrap trusted Stage kernels.
- `src/mb/v2/semantics`: MB_v2 semantic orchestration and evaluation contracts.
- `src/mb/v2/scene_stats`: MB_v2 scene-statistics evaluation.
- `src/mb/v2/exports`: MB_v2 export planning for canonical and smoke layers.
- `src/mb/v2/plots`: MB_v2 plotting that does not reuse the legacy MB plot pipeline.
- `src/analysis/mb_v2`: MB_v2-only analysis helpers.

## Stage05/06 Position

- Stage05/06 remain trusted kernel code.
- MB_v2 may reuse Stage05/06 only through adapters and wrappers.
- MB_v2 must not copy Stage05/06 source into a parallel implementation tree.
- Stage source files remain unchanged.

## Scope Of MB_v2

- Wrapper orchestration around trusted Stage behavior.
- closedD-oriented MB_v2 evolution where needed by future work.
- scene statistics and downstream reporting built on top of adapter outputs.
- New export and plotting contracts aligned to the canonical MB_v2 output tree.

## Not In Scope This Round

- Full algorithm migration from legacy MB.
- Any rewrite of Stage05/06 internals.
- Reuse of the legacy MB plot/export pipeline as the long-term active architecture.
