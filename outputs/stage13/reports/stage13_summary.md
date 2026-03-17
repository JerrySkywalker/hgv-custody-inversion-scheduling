# Stage13 baseline neighborhood search

## Summary

- mode: `baseline_neighborhood`
- baseline case: `N01`
- families: `2`
- candidates planned: `12`
- candidates evaluated: `12`
- summary table: `C:\src\hgv-cis-MA\outputs\stage13\tables\stage13_candidate_summary.csv`
- tier map: `C:\src\hgv-cis-MA\outputs\stage13\tables\stage13_candidate_tier_map.csv`
- dissertation export: `C:\src\hgv-cis-MA\outputs\stage13\reports\stage13_dissertation_export.md`
- dg refine enabled: `true`
- dg refine backup case: `dg_micro_07`
- dg refined summary: `C:\src\hgv-cis-MA\outputs\stage13\tables\stage13_dg_refined_candidate_summary.csv`
- dg micro summary: `C:\src\hgv-cis-MA\outputs\stage13\tables\stage13_dg_micro_candidate_summary.csv`

## Notes

Stage13 remains a search and candidate-management layer. It evaluates planned candidates with the MA-aligned truth window kernel, but it does not directly act as the MA export layer.
Current fixed mapping: `dt_first_probe_P6T4F0` is reserved for MA extension, `dg_micro_07` is backup for MB/defense, and `dg_first_probe_3` is kept only as a development trace.
DG refined review: dg_micro_07 shows a more active DG constraint than the original dg_first_probe_3 baseline probe (D_G^{worst}=0.792, D_A^{worst}=0.890, D_T^{worst}=1.000), but it is still reserved for backup or defense use instead of MA正文导出.
