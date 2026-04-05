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
- R8-C.2：outerB 回正为空泡校正环（R5 条件外壳对齐）
- R8-C.3：outerB 回正为空泡校正环（R5 内核对齐）

## R8-C.3 当前定义

R8-C.3 使用与 R5-real 相同的真实 future-window kernel：

- `predict_future_window_information(...)`
- `eval_window_information(...)`

不同点仅在于候选 pair 的排序准则，不再用 R5 的单一标量 gain，
而是使用 bubble-correction 词典序：

1. maximize Xi_B
2. maximize tau_B
3. minimize A_B
4. minimize switch cost
5. minimize resource cost

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
addpath(fullfile(pwd,'ch5_rebuild','outer_loop_A'));
addpath(fullfile(pwd,'ch5_rebuild','outer_loop_B'));
addpath(fullfile(pwd,'ch5_rebuild','runners'));

outC3 = run_ch5r_phase8_C3_outerB_bubble_correction_real_kernel();

