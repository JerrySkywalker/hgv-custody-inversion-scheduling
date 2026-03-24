# MB Legacy Freeze Policy

## Policy

- The existing MB implementation is frozen as legacy code.
- Legacy MB is retained only for reproducing historical results, audits, smoke checks, and previously documented delivery bundles.
- No new MB features should be added to legacy milestone logic, legacy MB runners, or legacy MB analysis helpers.

## Allowed Legacy Usage

- Re-run historical MB entrypoints for reproduction.
- Add wrappers, adapters, manifests, and documentation around the frozen legacy surface.
- Build indexes that classify historical outputs without deleting or renaming the original roots.

## Required Redirect

- All new MB development must move to `milestones/active/MB_v2`.
- All new runnable MB entrypoints must move to `run_milestones/active`.
- All new MB implementation code must move to `src/mb/v2` and `src/analysis/mb_v2`.
- All new MB governance and architecture notes must move to `docs/mb_v2`.

## Stage Constraint

- Stage files remain trusted kernel code.
- Stage05/06 reuse must happen only through wrappers or adapters.
- No Stage source file is modified by this freeze policy.
