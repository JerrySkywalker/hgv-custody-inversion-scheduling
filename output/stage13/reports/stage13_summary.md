# Stage13 baseline neighborhood search

## Summary

- mode: `baseline_neighborhood`
- baseline case: `N01`
- families: `2`
- candidates planned: `12`
- candidates evaluated: `12`
- summary table: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\stage13\tables\stage13_candidate_summary.csv`
- dissertation export: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\stage13\reports\stage13_dissertation_export.md`
- dg refine enabled: `true`
- dg refine recommended case: `dg_micro_07`
- dg refined summary: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\stage13\tables\stage13_dg_refined_candidate_summary.csv`
- dg micro summary: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\stage13\tables\stage13_dg_micro_candidate_summary.csv`

## Notes

This increment evaluates each planned candidate with the MA-aligned truth window kernel and stores a unified candidate signature table.
DG refined review: dg_micro_07 相比 dg_first_probe_3 已从 joint collapse 改善为 DG 主导退化，当前 D_G^{worst}=0.792, D_A^{worst}=0.890, D_T^{worst}=1.000；其中 DT 保持在门槛，但 DA 仍同步明显下降，因此更适合作为备选/答辩材料，不建议立即正文 cherry-pick。
