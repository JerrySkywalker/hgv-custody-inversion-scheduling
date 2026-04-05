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
- R8-A：空泡主变量重定义（Xi_B = S_r - D_r - eps_B）

## R8-A 当前定义

给定未来窗口长度 H，定义：

- 最弱供给下界
  S_r(k,H;u) = min M_G(k+ell|k;u)

- 最弱方向需求
  D_r(k,H) = rho_r * sum max(0, M_R(k+ell|k)) * dt

- 空泡裕度
  Xi_B(k,H;u) = S_r(k,H;u) - D_r(k,H) - eps_B

- 空泡风险
  R_B(k,H;u) = max(0, -Xi_B(k,H;u))

当前 R8-A 先以独立 smoke 形式落地，不直接破坏现有 R8.5 / R8.6 主线。

## 当前入口

```matlab
addpath(fullfile(pwd,'ch5_rebuild'));
addpath(fullfile(pwd,'ch5_rebuild','inner_loop'));
addpath(fullfile(pwd,'ch5_rebuild','outer_loop_A'));
addpath(fullfile(pwd,'ch5_rebuild','plots'));
addpath(fullfile(pwd,'ch5_rebuild','runners'));

out = run_ch5r_phase8_A_bubble_variable_smoke();

