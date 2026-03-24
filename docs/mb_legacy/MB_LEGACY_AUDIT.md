# MB Legacy Audit

## Scope

- Inventory legacy MB code, runners, docs, and output roots before physical consolidation into the legacy namespace.
- Exclude Stage source files from all migration candidates.

## Key Findings

- The main MB generation-one source modules are still spread across `src/mb/closedd`, `src/mb/compare`, `src/mb/legacydg`, and `src/mb/vgeom`.
- Old MB orchestration is split between `milestones`, `run_milestones`, and a large `run_stages/run_mb_*` surface.
- Historical MB outputs already fall naturally into canonical, archive, and smoke-style roots and can be indexed without deleting history.

- code: 100
- doc: 16
- output: 41
- runner: 16

## CSV Companion

- `docs/mb_legacy/MB_LEGACY_AUDIT.csv` contains the machine-readable migration list.
