# MB inverse slices

## Purpose

真值静态可行域、任务侧切片比较与最小布置提取。

## Inputs

- milestone_id: `MB`
- title: `inverse_slices`
- config timestamp: `2026-03-16 13:44:24`

## Reused Computational Modules

- Constellation slice packager
- Task-side slice packager
- Minimum-design extractor

## Outputs generated

### Tables

- `slice_grid_summary`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MB\tables\MB_inverse_slices_slice_grid_summary.csv`
- `feasible_domain_table`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MB\tables\MB_inverse_slices_feasible_domain_table.csv`
- `minimum_design_table`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MB\tables\MB_inverse_slices_minimum_design_table.csv`
- `near_optimal_design_table`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MB\tables\MB_inverse_slices_near_optimal_design_table.csv`
- `task_slice_summary`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MB\tables\MB_inverse_slices_task_slice_summary.csv`

### Figures

- `feasible_domain_map`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MB\figures\MB_inverse_slices_feasible_domain_map.png`
- `minimum_boundary_map`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MB\figures\MB_inverse_slices_minimum_boundary_map.png`
- `task_family_slice_comparison`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MB\figures\MB_inverse_slices_task_family_slice_comparison.png`

### Artifacts

- `temporal_metric_note`: `时序图表展示采用有界时序连续性裕度 DT_bar，闭合判定与主导失效识别继续采用标准化时序连续性裕度 DT >= 1。`


## Key preliminary findings

- `slice_axes`: h-i, P-T
- `num_grid_points`: 180
- `num_feasible_points`: 10
- `minimum_design`: struct(30 fields)
- `near_optimal_region_size`: 10
- `dominant_constraint_distribution`: struct(3 fields)
- `key_counts`: struct(2 fields)
- `success_flags`: struct(3 fields)
- `main_conclusion`: 真值静态可行域给出的最小布置对应 N_s=48。任务侧切片可行比例为 nominal=0.06, heading=0.06, critical=0.06。最小布置边界与主导失效识别均使用标准化时序连续性裕度 D_T。
