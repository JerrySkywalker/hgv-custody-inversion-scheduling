# MB Legacy Code Map

## Decision

This round keeps the old MB source modules in place and applies a soft legacy namespace policy instead of a physical move.

## Legacy Module Mapping

| Current Path | Logical Legacy Namespace | Status | Rule |
|---|---|---|---|
| `src/mb/closedd` | `src/mb/legacy/closedd` | frozen in place | no new feature work |
| `src/mb/compare` | `src/mb/legacy/compare` | frozen in place | no new feature work |
| `src/mb/legacydg` | `src/mb/legacy/legacydg` | frozen in place | no new feature work |
| `src/mb/vgeom` | `src/mb/legacy/vgeom` | frozen in place | no new feature work |

## Why Soft Migration

- The old MB tree already has many cross-references in milestone logic, `run_stages` orchestration, analysis helpers, and tracked output conventions.
- A physical move in this round would create avoidable path-risk without improving the Stage-isolation guarantees.
- The governance goal for this round is separation of ownership, not algorithm migration.

## Consequences

- Legacy MB source continues to run from its current physical paths.
- `src/mb/legacy/README_legacy_mapping.md` is the authoritative manifest for this soft mapping.
- All new MB implementation work must go to `src/mb/v2` and `src/analysis/mb_v2`.
- Any later physical migration should happen only after dedicated path-audit work and should still leave Stage files untouched.
