# ch5_rebuild

本目录用于第五章新主线重建。

## 当前状态

- R2-real：统一真实指标层
- R3-real：固定静态双星组合
- R4-real：动态双星组合调度
- R4c-real：真实静态 vs 真实动态对照包
- R5-real：局部 horizon + 切换平滑的前瞻补泡调度
- R5c-real：R3 / R4 / R5 对照包
- R6-real：空泡到需求界限失守的最小后果链分析
- R7-real：最小双环增强版
- R8.1：内环滤波底座接入
- R8.2：NIS 一致性监视正式接入
- R8.3a：动态窗口 Gramian + 关键子空间 M_G 修补版
- R8.4：outerA 上界 \tilde{M}_R 实现
- R8.5b：outerB 评分重标定版
- R8.6-real：真实分支 compare 接入版
- R8.6b：高压力可区分性增强尝试
- R8-A-redo：requirement-induced bubble main variable
- R8-B：outerA 回正为空泡预测环
- R8-C：outerB 回正为空泡校正环（synthetic smoke）
- R8-C.2：outerB 回正为空泡校正环（R5 条件对齐版）

## R8-A-redo 当前定义

给定未来窗口长度 H，定义：

- requirement margin forecast
  margin(ell) = Gamma_req - lambda_max(P_r,k+ell|k^+)

- requirement-induced bubble margin
  Xi_B(k,H) = min_{ell=1,...,H} margin(ell)

- bubble risk
  R_B(k,H) = max(0, -Xi_B(k,H))

这一版本不使用人工超参数 rho_r / eps_B，直接由 requirement 上限与未来 P_r^+ 轨迹定义 bubble 主变量。

## R8-B 当前定义

outerA 直接输出未来窗口空泡预测量：

- Xi_B : 最坏 requirement 裕度
- tau_B: 首次失守时刻
- A_B  : requirement 失守面积

## R8-C 当前定义

outerB 不再用人工加权，而采用词典序 bubble correction：

1. maximize Xi_B
2. maximize tau_B
3. minimize A_B
4. minimize switch cost
5. minimize resource cost

## R8-C.2 当前定义

R8-C.2 与 R5-real 对齐：

- 使用同源 `default_ch5r_params(true)` + `build_ch5r_case(cfg)`
- 使用真实时变 `pair_bank{k}`
- 使用真实时变卫星位置
- 保持 Xi_B / tau_B / A_B 词典序 bubble correction 逻辑

## 当前入口

```matlab
addpath(fullfile(pwd,'ch5_rebuild'));
addpath(fullfile(pwd,'ch5_rebuild','inner_loop'));
addpath(fullfile(pwd,'ch5_rebuild','outer_loop_A'));
addpath(fullfile(pwd,'ch5_rebuild','outer_loop_B'));
addpath(fullfile(pwd,'ch5_rebuild','plots'));
addpath(fullfile(pwd,'ch5_rebuild','runners'));

outA  = run_ch5r_phase8_A_bubble_variable_smoke();
outB  = run_ch5r_phase8_B_outerA_bubble_prediction();
outC  = run_ch5r_phase8_C_outerB_bubble_correction();
outC2 = run_ch5r_phase8_C2_outerB_bubble_correction_aligned();

