# ch5_rebuild

本目录用于第五章新主线重建，当前阶段为 **Phase R0**。

## 当前原则

1. 不改第四章 Stage 系列核心实现。
2. 不在 R0 直接复用旧 `ch5_dualloop` 的策略层实现。
3. 只建立第五章自己的参数 bootstrap 适配层。
4. 旧 `ch5_dualloop` 在 R0 中视为 **frozen legacy**，仅保留参考，不作为新主线入口。

## 当前 R0 目标

- 建立 `ch5_rebuild/` 新目录骨架
- 从 Stage04 / Stage05 cache 与默认参数中自动提取：
  - `theta_star`
  - `theta_plus`
  - baseline sensor profile
  - representative target case
  - `gamma_req`
- 输出一个可供 R1 继续使用的统一 `cfg.ch5r` 结构

## 当前不做的事

- 不做调度器
- 不做 inner / outer loop
- 不改 `run_all_stages`
- 不物理迁移 `ch5_dualloop`

## MATLAB 使用

R0 阶段建议显式加路径：

```matlab
addpath(fullfile(pwd,'ch5_rebuild'));
addpath(fullfile(pwd,'ch5_rebuild','params'));
addpath(fullfile(pwd,'ch5_rebuild','bootstrap'));
然后调用：

cfg = default_ch5r_params();
bundle = bootstrap_ch5r_from_stage04_stage05(cfg);

