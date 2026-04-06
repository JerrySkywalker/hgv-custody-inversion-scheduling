# ch5_bubble

第五章实验新主线目录。

## 当前 B1 路线

B1 已切换为：

manual recipe
-> synthetic case
-> Stage02 propagation kernel
-> trajectory sample
-> 3D plots

这意味着：

- 第五章不再依赖 Stage01 的批量 casebank；
- 但仍然复用 Stage02 的真实传播内核；
- 每条轨迹由 `default_ch5b_trajectory_recipes.m` 明确给出；
- 更适合第五章的小样本、高解释性、可控对比实验。

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
- `runners/run_ch5b_phaseB1_plot_smoke.m`

