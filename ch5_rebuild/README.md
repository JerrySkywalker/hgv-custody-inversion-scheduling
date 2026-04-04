# ch5_rebuild

本目录用于第五章新主线重建。

## 当前状态（R3-real / R4-real / R4c-real 主线）

旧的 proxy 版本已废弃，不再允许：
- theta_star / theta_plus 整构型切换
- synthetic info proxy
- policy-aware gain proxy

新的 R3 / R4 目标：
- 使用真实 Stage02 HGV 轨迹
- 使用固定同一真实星座（theta_star）
- 使用 Stage03 真实可见性与 LOS 几何
- R3-real：固定静态双星组合
- R4-real：动态双星组合调度
- R4c-real：真实静态 vs 真实动态对照包
- 使用真实 bearing-only Fisher 信息

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
addpath(fullfile(pwd,'ch5_rebuild','runners'));

out3 = run_ch5r_phase3_static_bubble_demo();
out4 = run_ch5r_phase4_tracking_baseline();
out4c = run_ch5r_phase4_compare_bundle_real();
