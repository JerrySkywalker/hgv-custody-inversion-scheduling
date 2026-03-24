# MB Refactor Audit

## Scope

- Inventory MB-related code, runners, docs, and output roots before freezing legacy MB.
- Preserve all existing Stage source files and Stage runner business logic untouched.
- Use this audit as the basis for legacy/active split, output reclassification, and MB_v2 governance.

## Key Findings

- The current MB implementation surface is spread across milestone helpers, `run_stages/run_mb_*` orchestration, `src/mb/{closedd,compare,legacydg,vgeom}`, and many MB-only analysis helpers under `src/analysis/`.
- `outputs/milestones/MB` is a mixed historical root and should be frozen as legacy provenance instead of continuing as the default formal output root.
- Existing fresh-root rebuilds, strict validations, smoke runs, vgeom probes, and delivery bundles can be reorganized by manifest into canonical/archive/smoke layers without deleting history.
- Root-level MB notes and README files document prior rounds; new policy and architecture docs should move to `docs/mb_v2/`.

## Counts

- code: 108
- doc: 16
- output: 42
- runner: 17

## Immediate Legacy Surface

- `milestones/mb_modes.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/mb_output_paths.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/mb_search_profile_catalog.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/mb_search_profile_defaults.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/milestone_B_inverse_slices.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/milestone_B_semantic_compare.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/milestone_common_defaults.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/milestone_common_export_summary.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/milestone_common_output_paths.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/milestone_common_plot_style.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/milestone_common_save_figure.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.
- `milestones/milestone_common_save_table.m` | Old MB milestone helpers and orchestration; freeze in place and redirect new work to MB_v2.

## Active Redirect Surface

- `README.md` | MB-related project note or delivery readme; root README should later point new MB work to docs/mb_v2.

## Output Roots Requiring Classification

- `outputs/milestones/MB` | proposed=`archive` | Mixed legacy root with tracked and untracked MB artifacts; treat as frozen historical source, not a future canonical write target.
- `outputs/milestones/MB_20260323_final_repair_fullnight` | proposed=`archive` | Historical MB output root retained in place for provenance; classify via refactor indexes.
- `outputs/milestones/MB_vgeom_h1000_coarse_20260324` | proposed=`archive` | Historical MB output root retained in place for provenance; classify via refactor indexes.
- `outputs/milestones/MB_vgeom_h1000_debugmini` | proposed=`archive` | Historical MB output root retained in place for provenance; classify via refactor indexes.
- `outputs/milestones/MB_vgeom_plotprobe` | proposed=`archive` | Historical MB output root retained in place for provenance; classify via refactor indexes.
- `outputs/milestones/MB_vgeom_plotprobe2` | proposed=`archive` | Historical MB output root retained in place for provenance; classify via refactor indexes.
- `outputs/milestones/MB_20260323_final_repair_strict` | proposed=`canonical` | Strict reference output root; candidate canonical reference for Stage05/06 replication checks.
- `outputs/milestones/MB_20260323_fullrebuild_baseline` | proposed=`canonical` | Fresh-root or rebuild lineage output with higher archival value; likely canonical reference candidate.
- `outputs/milestones/MB_20260323_fullrebuild_delivery` | proposed=`canonical` | Curated delivery-style bundle; candidate source for recommended references after indexing.
- `outputs/milestones/MB_20260323_fullrebuild_strict` | proposed=`canonical` | Strict reference output root; candidate canonical reference for Stage05/06 replication checks.
- `outputs/milestones/MB_20260323_globalfulldense_baseline` | proposed=`canonical` | Fresh-root or rebuild lineage output with higher archival value; likely canonical reference candidate.
- `outputs/milestones/MB_20260323_globalfulldense_delivery` | proposed=`canonical` | Curated delivery-style bundle; candidate source for recommended references after indexing.

## CSV Companion

- Full machine-readable inventory: `docs/mb_v2/MB_REFACTOR_AUDIT.csv`

