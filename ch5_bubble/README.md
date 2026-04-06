# ch5_bubble

第五章实验新主线目录。

## 当前 B1 路线

B1 已切换为：

manual recipe
-> synthetic case
-> Stage02 propagation kernel
-> trajectory sample
-> diagnostic plots

## B1.1 增强

当前 recipe 已支持每条轨迹单独设置：

- `h0_m`
- `v0_mps`
- `theta0_deg`
- `sigma0_deg`
- `heading_deg`
- `heading_offset_deg`
- `alpha_cmd_deg`
- `bank_cmd_deg`

当前诊断图包括：

- 3D 轨迹图
- 高度-时间图
- 速度-时间图

## 测试入口

当前已提供：

- `tests/test_ch5b_plot_trajectory_3d.m`

用于对代表性轨迹生成单独 3D 图和叠加 3D 图，便于人工检查与最小 CI smoke。

## 当前关键文件

- `params/default_ch5b_params.m`
- `params/default_ch5b_trajectory_recipes.m`
- `trajectory_manager/build_manual_case_from_recipe_ch5b.m`
- `trajectory_manager/build_trajectory_registry.m`
- `trajectory_manager/resolve_trajectory_sample.m`
- `trajectory_manager/summarize_trajectory_sample.m`
- `trajectory_manager/diagnose_trajectory_timeline.m`
- `plots/plot_ch5b_trajectory_3d.m`
- `plots/plot_ch5b_trajectory_family_3d.m`
- `plots/plot_ch5b_altitude_time.m`
- `plots/plot_ch5b_speed_time.m`
- `plots/export_ch5b_diagnostic_plots.m`
- `runners/run_ch5b_phaseB1_plot_smoke.m`
- `tests/test_ch5b_plot_trajectory_3d.m`

