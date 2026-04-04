# ch5_rebuild

本目录用于第五章新主线重建。

## 当前状态（R2-real / R3-real / R4-real / R4c-real / R5 / R5c-real / R6-real / R7-real / R8-real / R8.1 / R8.2 / R8.3a / R8.4 / R8.5a 主线）

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
- R8-real：弱先验接入负结果验证
- R8.1：内环滤波底座接入（预测 + EKF 更新 + 创新协方差）
- R8.2：NIS 一致性监视正式接入
- R8.3a：动态窗口 Gramian + 关键子空间 M_G 修补版
- R8.4：outerA 上界 \tilde{M}_R 实现
- R8.5a：outerB 动作层激活修补版

## 当前入口

```matlab
addpath(fullfile(pwd,'ch5_rebuild'));
addpath(fullfile(pwd,'ch5_rebuild','inner_loop'));
addpath(fullfile(pwd,'ch5_rebuild','outer_loop_A'));
addpath(fullfile(pwd,'ch5_rebuild','outer_loop_B'));
addpath(fullfile(pwd,'ch5_rebuild','plots'));
addpath(fullfile(pwd,'ch5_rebuild','analysis'));
addpath(fullfile(pwd,'ch5_rebuild','runners'));

out = run_ch5r_phase8_5_outerB_continuous();

