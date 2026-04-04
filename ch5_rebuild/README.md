# ch5_rebuild

本目录用于第五章新主线重建。

## 当前状态（R2-real / R3-real / R4-real / R4c-real / R5 / R5c-real / R6-real / R7-real / R8-real 主线）

旧的 proxy 版本已废弃，不再允许：
- theta_star / theta_plus 整构型切换
- synthetic info proxy
- policy-aware gain proxy

新的主线：
- 使用真实 Stage02 HGV 轨迹
- 使用固定同一真实星座（theta_star）
- 使用 Stage03 真实可见性与 LOS 几何
- R2-real：统一真实指标层
- R3-real：固定静态双星组合
- R4-real：动态双星组合调度
- R4c-real：真实静态 vs 真实动态对照包
- R5-real：局部 horizon + 切换平滑的前瞻补泡调度
- R5c-real：R3 / R4 / R5 对照包，并绘制 RMSE proxy 曲线
- R6-real：空泡到需求精度界限失守的最小后果链分析
- R7-real：最小双环增强版，对比单环与双环触发机制
- R8-real：弱先验接入（tie-break 版）
- 使用真实 bearing-only Fisher 信息

## 说明

- 当前 `rmse_proxy_metrics` 是 Fisher-based RMSE proxy
- 当前 `R6-real` 是 requirement-risk proxy
- 当前 `R7-real` 是 minimal dual-loop shell
- 当前 `R8-real` 是 weak-prior tie-break，不是强先验控制

## 当前入口

```matlab
addpath(fullfile(pwd,'ch5_rebuild'));
addpath(fullfile(pwd,'ch5_rebuild','params'));
addpath(fullfile(pwd,'ch5_rebuild','bootstrap'));
addpath(fullfile(pwd,'ch5_rebuild','scenario'));
addpath(fullfile(pwd,'ch5_rebuild','state'));
addpath(fullfile(pwd,'ch5_rebuild','metrics'));
addpath(fullfile(pwd,'ch5_rebuild','policies'));
addpath(fullfile(pwd,'ch5_rebuild','allocator'));
addpath(fullfile(pwd,'ch5_rebuild','plots'));
addpath(fullfile(pwd,'ch5_rebuild','sensing'));
addpath(fullfile(pwd,'ch5_rebuild','core'));
addpath(fullfile(pwd,'ch5_rebuild','analysis'));
addpath(fullfile(pwd,'ch5_rebuild','outer_loop'));
addpath(fullfile(pwd,'ch5_rebuild','prior'));
addpath(fullfile(pwd,'ch5_rebuild','runners'));

out8 = run_ch5r_phase8_weak_prior_compare();

