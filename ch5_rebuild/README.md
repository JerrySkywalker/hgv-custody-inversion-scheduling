# ch5_rebuild

本目录用于第五章新主线重建。

## 当前状态（R4 重写中）

旧的 R4 proxy 版本已废弃，不再允许：
- theta_star / theta_plus 整构型切换
- synthetic info proxy
- policy-aware gain proxy

新的 R4 目标：
- 使用真实 Stage02 HGV 轨迹
- 使用固定同一真实星座（theta_star）
- 使用 Stage03 真实可见性与 LOS 几何
- 在同一星座内做双星组合调度
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
addpath(fullfile(pwd,'ch5_rebuild','runners'));

out4 = run_ch5r_phase4_tracking_baseline();
