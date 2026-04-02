# Phase 9：窗口长度主扫描

## 目标

Phase 9 是第五章后续唯一主自变量扫描，用于系统分析窗口长度 `T_w` 对动态调度效果的影响。

## 比较对象

- `T`
- `C`
- `CK`
- `CK + NX2 dwell-final`

## 场景

- `ref128`
- `stress96`

## 扫描网格

- `T_w = [10, 20, 30, 40, 60, 80]`

## 输出指标

- `q_worst_window`
- `q_worst_point`
- `phi_mean`
- `outage_ratio`
- `longest_outage_steps`
- `mean_rmse`
- `max_rmse`
- `switch_count`
- `applied_switch_count`

## 预期论文意义

这一实验用于回答：

1. 窗口过短时，算法是否过于贪心
2. 窗口过长时，是否受到预测误差与结构失配影响
3. 是否存在合理的工作区间
4. `CK` 相对 `C/T` 的优势是否在某个窗口区间最明显

## 当前约束

本轮不再扩展：

- prior online coupling
- proposal online coupling
- degrade-mode guard
- 其他 exploratory 路线

只围绕冻结主线完成主扫描。
