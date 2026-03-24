# MB Legacy Namespace Mapping

This directory is the policy anchor for the frozen MB legacy namespace.

## Soft-Migration Mapping

- `src/mb/closedd` -> logical legacy namespace `src/mb/legacy/closedd`
- `src/mb/compare` -> logical legacy namespace `src/mb/legacy/compare`
- `src/mb/legacydg` -> logical legacy namespace `src/mb/legacy/legacydg`
- `src/mb/vgeom` -> logical legacy namespace `src/mb/legacy/vgeom`

## Current Round Decision

- Physical moves are intentionally deferred to avoid breaking existing path assumptions.
- Existing callers may continue to reference the original directories during the legacy period.
- MB_v2 must not add new feature work into these original directories.

## Forward Rule

- Treat the original directories as frozen implementation storage.
- Treat this document as the namespace manifest that explains their legacy ownership.
