# MA truth baseline

## Purpose

Single-layer static inverse-design truth baseline.

## Inputs

- milestone_id: `MA`
- title: `truth_baseline`
- config timestamp: `2026-03-16 21:20:03`

## Reused Computational Modules

- Controlled truth-baseline evaluator
- Single-case window truth scanner

## Outputs generated

### Tables

- `baseline_configuration_summary`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MA\tables\MA_truth_baseline_configuration_summary.csv`
- `worst_window_identification`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MA\tables\MA_truth_baseline_worst_window_identification.csv`
- `window_level_truth_curve`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MA\tables\MA_truth_baseline_window_level_truth_curve.csv`

### Figures

- `truth_window_scan`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MA\figures\MA_truth_baseline_truth_window_scan.png`
- `worst_window_highlight`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\milestones\MA\figures\MA_truth_baseline_worst_window_highlight.png`

### Artifacts

- `baseline_evaluator`: `controlled truth-baseline evaluator`
- `window_scan_engine`: `single-case window truth scanner`
- `shared_scenario_SS1`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\shared_scenarios\SS1\figures\SS1_defense_zone_2d_overview.png`
- `shared_scenario_SS2`: `C:\Users\jerry\OneDrive\HIT-ASSL\202407-硕士毕业设计\20260112-结题\cpt4_sim_dev\output\shared_scenarios\SS2\figures\SS2_earth_walker_defense_zone_3d.png`
- `shared_scenario_note`: `共享场景 SS1/SS2 用于补充第四章与第五章共用的防区与 Earth-Walker 空间关系说明。`
- `temporal_display_note`: `图形展示采用有界时序连续性裕度 DT_bar；闭合判定采用标准化时序连续性裕度 DT >= 1。`
- `temporal_panel_note`: `基线真值窗口扫描的第三面板展示 \\bar{D}_T，显示阈值为 0.5；真值可行性仍按 D_T^{worst} >= 1 判定。`


## Key preliminary findings

- `case_id`: N01
- `theta_baseline`: struct(5 fields)
- `Tw_baseline`: 60
- `DT_bar_worst`: 0.5
- `DT_worst`: 1
- `DG_worst_truth`: 1.3739
- `DA_worst_truth`: 1.1722
- `DT_worst_truth`: 1
- `t0G_star`: 0
- `t0A_star`: 0
- `t0T_star`: 0
- `dt_max_at_worst`: 60
- `is_feasible_truth`: true
- `dominant_metric`: DT
- `key_counts`: struct(3 fields)
- `success_flags`: struct(2 fields)
- `main_conclusion`: 基线设计在真值判定下可行。图中时序曲线展示为有界时序连续性裕度 \bar{D}_T，显示阈值取 0.5；闭合判定仍按标准化时序连续性裕度 D_T = 2\bar{D}_T 且 D_T^{worst} \ge 1 执行。当前 DG=1.374，DA=1.172，D_T=1.000，\bar{D}_T=0.500，主导指标为 DT。
