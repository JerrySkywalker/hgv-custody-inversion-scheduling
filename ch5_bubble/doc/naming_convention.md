# ch5_bubble 命名规范

## 1. 总体原则

统一前缀：`ch5b`

理由：
- 与旧 `ch5_rebuild` 区分；
- 便于 grep / 全局检索；
- 便于后期打包与迁移。

## 2. 文件命名

### 2.1 参数入口
- `default_ch5b_params.m`
- `merge_ch5b_params.m`（后续可加）

### 2.2 轨迹管理器
- `build_trajectory_registry.m`
- `load_stage02_trajectory_family.m`
- `resolve_trajectory_sample.m`
- `summarize_trajectory_sample.m`

### 2.3 case builder
- `build_ch5b_case.m`
- `summarize_ch5b_case.m`
- `validate_ch5b_case.m`

### 2.4 策略
- `policy_static_hold.m`
- `policy_tracking_greedy.m`
- `policy_bubble_predictive.m`
- `policy_li_xxx.m`

### 2.5 注册与调度
- `register_builtin_strategies.m`
- `run_policy_by_name.m`

### 2.6 指标
- `eval_bubble_metrics.m`
- `eval_lambda_metrics.m`
- `eval_rmse_metrics.m`
- `package_metric_bundle.m`

### 2.7 runner
- `run_ch5b_phaseB0_smoke.m`
- `run_ch5b_phase6_static_vs_tracking_vs_bubble.m`
- `run_ch5b_phase7_li_compare.m`

## 3. 变量命名

### 3.1 ID 规则
- `sample_id`：轨迹样本 id
- `family_id`：轨迹族 id
- `case_id`：实验 case id
- `policy_name`：策略名

### 3.2 结构体对象名
- `cfg`：总配置
- `traj_sample`：轨迹样本
- `case_artifact`：标准 case 工件
- `selection_trace`：策略输出轨迹
- `metric_bundle`：指标总包
- `out`：runner 输出总结构

## 4. 输出目录命名

后续统一使用：

`outputs/ch5_bubble/<phase_name>/...`

例如：
- `outputs/ch5_bubble/phaseB0_smoke/`
- `outputs/ch5_bubble/phaseB1_registry/`
- `outputs/ch5_bubble/phaseB6_compare/`

## 5. 禁止事项

- 不允许新链文件继续混入 `Phase R` 风格命名；
- 不允许 compare runner 内部直接 hardcode 某个策略实现；
- 不允许 plotting 文件名使用含糊命名如 `test1.m`、`temp_plot.m`；
- 不允许同一概念出现多个别名。

