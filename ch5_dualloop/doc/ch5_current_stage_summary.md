# 第五章当前阶段总结（阶段性收口）

## 1. 当前统一实验主线

第五章当前已经形成一个清晰的统一实验平台，主线比较对象为：

- `S`：静态保持基线法
- `T`：tracking-oriented dynamic，传统动态跟踪导向法
- `C`：custody-oriented single-loop，单环托管导向动态法
- `CK`：custody-oriented dual-loop Koopman，双环托管法

这一主线与此前的实验规划保持一致：第五章不是做许多互相独立的小实验，而是在同一平台中逐 phase 增加功能，并最终围绕 `S/T/C/CK` 四类方法完成统一论证。

## 2. 当前已经完成并有结果支撑的部分

### 2.1 S 与 T 的对比已经成立

阶段结果已经表明：

- `S` 在 coverage 与 RMSE 上明显弱于 `T`
- 这支撑了“静态规律有价值，但静态保持不能替代真正动态调度”的命题

这与第五章原定的 Phase 4 目标一致。

### 2.2 C 与 CK 的主线对比已经成立

当前 `Phase7A` 结果表明：

- 在 `ref128` 场景下，`CK q_worst_window = 0.439412`，高于 `C q_worst_window = 0.398767`
- 在 `stress96` 场景下，`CK q_worst_window = 0.426186`，高于 `C q_worst_window = 0.376955`

这说明双环 CK 相对单环 C，在最坏窗口托管性能上已经形成稳定增益。

### 2.3 CK 消融实验已经给出关键信息

当前 `Phase7B` / `NX-1` 的结果已经说明：

- 去掉 geometry 后，`CK-noGeom` 在两个场景中都明显恶化
- 去掉 state-machine 后，结果会分离，但作用弱于 geometry

因此可以形成当前结论：

- geometry 是 CK 的主骨架
- state-machine 是重要增强层，但当前仍属于较弱版本

### 2.4 NX-2 已证明最小状态机壳子中的 dwell 有效

当前定型结果已经冻结为：

- `nx2_dwell_steps = 16`
- `nx2_guard_enable = false`
- `nx2_guard_ttl_steps = 8`

其中，`dwell=16` 在 `ref128` 上能够压低切换数，同时不降低 `q_worst_window`，并略微改善 `outage_ratio`。

### 2.5 NX-3 已证明组合 guard 比 TTL-only 更强，但仍主要作用于内部动作层

NX-3 第一轮表明：

- 组合 guard 能明显降低 `applied_switch_count`
- 但尚未显著改变最终的 `q_worst_window / outage_ratio / switch_count`

随后并行测试了两类 guard-action：

- A：freeze selection
- B：degrade mode

结果显示：

- A 与 base 等价，没有副作用
- B 会损伤几何质量与最终托管表现，因此不采纳

所以当前 guard 主线应保留 base / A 方向，不采用 B。

### 2.6 Phase 8 / NX-4 已经证明：静态先验作为在线主链增强器目前不成立

当前结果已经清楚表明：

- reference prior 直接接入会导致性能恶化或无法形成稳定收益
- proposal-only 层有信息量，但 soft coupling 无法撬动当前主链 selection
- 因此，第四章静态知识目前更适合作为：
  - reference layer
  - explanation layer
  - diagnostic layer
而不是在线 hard / soft selection enhancer

## 3. 当前阶段已经可以形成的中间结论

1. 第四章静态规律不能直接替代第五章动态调度。
2. 第五章的主线增益首先来自 geometry-aware 的托管导向选择。
3. 在当前实现中，最小状态机壳子中的 dwell 已被证明有效。
4. TTL-only guard 不够强，组合 guard 虽更合理，但目前主要压制内部动作，尚未强力改变最终 selection。
5. 第四章静态模板知识目前不宜直接在线耦合到主链 objective，应保留为独立参考/解释层。

## 4. 当前阶段尚未完成的核心任务

### 4.1 窗口长度主扫描（Phase 9）尚未完成

按照原规划，第五章唯一主自变量扫描应是窗口长度 `T_w` 扫描，用以验证：

- 过短窗口趋于贪心
- 过长窗口受预测误差与结构失配影响
- 存在合理工作区间

这一步目前仍然缺失。

### 4.2 正式论文图表包导出（Phase 10）尚未完成

虽然当前已有多项阶段性结果，但尚未形成：

- 统一命名的主图
- 汇总表
- release markdown
- 论文直接可用的 final bundle

### 4.3 外环 A 的需求识别能力仍不够强

Phase 6B 结果显示，当前 outerA 与坏窗口的对齐能力较弱，存在较高 miss / false alarm。这说明双环中的外环 A 还不是“强证据层”，而更多是“已接线但需加强”的证据层。

## 5. 当前推荐冻结的统一实验主线

建议当前将第五章主线冻结为：

- `S`
- `T`
- `C`
- `CK`
- `CK + NX2 dwell (final)`

其中：

- `CK + NX3 guard` 可作为补充分析，不作为当前主线结果
- `Phase8/NX4 proposal` 仅作为解释与诊断层保留，不进入统一主线

## 6. 当前阶段的工程判断

当前第五章并没有“实验失败”，而是已经完成了从探索性开发到主线收缩的过程。更准确地说：

- 主线：已经收敛
- 增强层：已经筛掉不合适路线
- 缺失项：主要集中在最终主扫描与图表收口

因此，第五章下一步的重点不应继续扩 exploratory 路线，而应转入：

1. 主线冻结
2. 窗口长度主扫描
3. release 图表包导出
