# MC window scale

## Purpose

Window-scale effect study for feasible set, worst-window shifts, and static closure.

## Inputs

- milestone_id: `MC`
- title: `window_scale`
- config timestamp: `2026-03-16 13:58:12`

## Reused Computational Modules

- stage08_boundary_window_sensitivity
- stage09_validate_window_kernel
- stage09_validate_single_design

## Outputs generated

### Tables

- `static_closure_summary`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MC\tables\MC_window_scale_static_closure_summary.csv`
- `worst_window_shift`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MC\tables\MC_window_scale_worst_window_shift.csv`
- `minimum_design_by_Tw`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MC\tables\MC_window_scale_minimum_design_by_Tw.csv`

### Figures

- `feasible_region_vs_Tw`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MC\figures\MC_window_scale_feasible_region_vs_Tw.png`
- `worst_window_shift`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MC\figures\MC_window_scale_worst_window_shift.png`
- `three_metric_vs_Tw`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MC\figures\MC_window_scale_three_metric_vs_Tw.png`

### Artifacts

- `stage08_window_sensitivity_error`: `No cache matched pattern: stage08_define_window_scope_milestoneC_*.mat`
- `stage09_validation_Tw_30`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\results\cache\stage09_validate_single_design_milestoneC_Tw30_20260316_135817.mat`
- `stage09_validation_Tw_60`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\results\cache\stage09_validate_single_design_milestoneC_Tw60_20260316_135830.mat`
- `stage09_validation_Tw_90`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\results\cache\stage09_validate_single_design_milestoneC_Tw90_20260316_135836.mat`
- `stage09_validation_Tw_120`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\results\cache\stage09_validate_single_design_milestoneC_Tw120_20260316_135841.mat`
- `temporal_metric_note`: `MC 曲线展示采用 DT_bar_worst，闭合判定与主导指标表继续采用 DT_worst >= 1。`


## Key preliminary findings

- `Tw_list`: [30 60 90 120]
- `feasible_count_by_Tw`: [0 0 0 0]
- `minimum_design_by_Tw`: struct(5 fields), struct(5 fields), struct(5 fields), struct(5 fields)
- `DT_bar_worst_by_Tw`: [0.0696864111498258 0.0696864111498258 0.0696864111498258 0.0696864111498258]
- `DT_worst_by_Tw`: [0.139372822299652 0.139372822299652 0.139372822299652 0.139372822299652]
- `t0G_star_by_Tw`: [3 6 9 12]
- `t0A_star_by_Tw`: [4.5 9 13.5 18]
- `t0T_star_by_Tw`: [6 12 18 24]
- `dominant_metric_by_Tw`: GAT, GAT, GAT, GAT
- `static_closure_flag_by_Tw`: [0 0 0 0]
- `key_counts`: struct(2 fields)
- `success_flags`: struct(1 fields)
- `main_conclusion`: Feasible Tw count=0/4; static closure achieved for 0 settings.
