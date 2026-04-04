# ch5_rebuild

本目录用于第五章新主线重建，当前已完成 **Phase R0**，正在完成 **Phase R1**。

## 当前原则

1. 不改第四章 Stage 系列核心实现。
2. 不直接复用旧 `ch5_dualloop` 的策略层实现。
3. 只建立第五章自己的 bootstrap、scenario、state 骨架。
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

## 当前完成：R1

R1 已建立最小状态链：

- 最小 case builder
- rolling-window information evaluator
- bubble state evaluator
- unified state trace packager

当前最小链路为：

`case -> Y_W(t) -> lambda_min(Y_W) -> bubble flag -> bubble segment -> state_trace`

正式入口：

- `run_ch5r_phase1_smoke`

当前 R1 不做：

- 不做滤波器
- 不做动态调度
- 不做双环
- 不做复杂 plotting

## MATLAB 使用

```matlab
addpath(fullfile(pwd,'ch5_rebuild'));
addpath(fullfile(pwd,'ch5_rebuild','params'));
addpath(fullfile(pwd,'ch5_rebuild','bootstrap'));
addpath(fullfile(pwd,'ch5_rebuild','scenario'));
addpath(fullfile(pwd,'ch5_rebuild','state'));
addpath(fullfile(pwd,'ch5_rebuild','runners'));

out0 = run_ch5r_phase0_bootstrap_smoke();
out1 = run_ch5r_phase1_smoke();

