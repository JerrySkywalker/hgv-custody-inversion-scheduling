# ch5_rebuild

本目录用于第五章新主线重建，当前已完成 **Phase R0**、**Phase R1**、**Phase R2**，正在进入 **Phase R3**。

## 当前原则

1. 不改第四章 Stage 系列核心实现。
2. 不直接复用旧 `ch5_dualloop` 的策略层实现。
3. 先建立第五章自己的 bootstrap、scenario、state、metrics、policy 骨架。
4. 旧 `ch5_dualloop` 视为 frozen legacy。

## 已完成：R0

- 建立 `ch5_rebuild/` 新目录骨架
- 从 Stage04 / Stage05 cache 与默认参数中自动提取：
  - `theta_star`
  - `theta_plus`
  - baseline sensor profile
  - representative target case
  - `gamma_req`

正式入口：

- `run_ch5r_phase0_bootstrap_smoke`

## 已完成：R1

R1 已建立最小状态链：

- 最小 case builder
- rolling-window information evaluator
- bubble state evaluator
- unified state trace packager

正式入口：

- `run_ch5r_phase1_smoke`

## 已完成：R2

R2 已建立最小指标层：

- bubble metrics
- requirement-margin proxy
- unified result packager

正式入口：

- `run_ch5r_phase2_metrics_smoke`

## 当前进行：R3

R3 当前只建立第一条正式策略基线：

- `policy_static_hold`
- `select_satellite_set_static`
- `run_ch5r_phase3_static_bubble_demo`

正式入口：

- `run_ch5r_phase3_static_bubble_demo`

当前 R3 不做：

- 不做 tracking greedy
- 不做 bubble predictive
- 不做双环
- 不做真实动态切换
- 不做复杂 plotting

## MATLAB 使用

```matlab
addpath(fullfile(pwd,'ch5_rebuild'));
addpath(fullfile(pwd,'ch5_rebuild','params'));
addpath(fullfile(pwd,'ch5_rebuild','bootstrap'));
addpath(fullfile(pwd,'ch5_rebuild','scenario'));
addpath(fullfile(pwd,'ch5_rebuild','state'));
addpath(fullfile(pwd,'ch5_rebuild','metrics'));
addpath(fullfile(pwd,'ch5_rebuild','policies'));
addpath(fullfile(pwd,'ch5_rebuild','allocator'));
addpath(fullfile(pwd,'ch5_rebuild','runners'));

out0 = run_ch5r_phase0_bootstrap_smoke();
out1 = run_ch5r_phase1_smoke();
out2 = run_ch5r_phase2_metrics_smoke();
out3 = run_ch5r_phase3_static_bubble_demo();
