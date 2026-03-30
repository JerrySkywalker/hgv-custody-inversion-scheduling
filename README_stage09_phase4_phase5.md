# Stage09 Phase4 / Phase5 状态说明

## 一、当前范围

当前 Stage09 后处理组织方式分为两条线：

### A. 平面图线（保留原语义）
用于表达固定切片下，不同指标的闭合关系：

- Phase4-A：多高度 heatmap pack
- Phase4-B：固定 `h` 的四层 closure heatmap
- Phase4-C：固定 `P` 的 `h-i` closure heatmap guarded feature

### B. 3D 图线（Phase5 重构）
用于表达同一指标在不同高度 `h` 下的堆叠结构：

- joint 的多高度 stack3d
- DG 的多高度 stack3d
- DA 的多高度 stack3d
- DT 的多高度 stack3d

---

## 二、为什么这样重构

原因是：

- `joint / DG / DA / DT` 物理意义不同
- 不能强行放在同一张 3D 图中共用一个色标
- 那样会导致解释混乱、量纲不一致、可比性差

因此：

- 不同指标之间的关系仍由 **平面 closure heatmaps** 表达
- 同一指标随高度的变化改由 **metric-wise stack3d-over-h** 表达

---

## 三、Phase4

### Phase4-A

入口：

- `tests/manual/manual_smoke_stage09_phase4_multih_heatmaps.m`

作用：

- 基于 `base.cubes.metric_over_h_i_P`
- 输出多高度平面 heatmap pack

---

### Phase4-B

入口：

- `tests/manual/manual_smoke_stage09_phase4_closure_heatmaps.m`

作用：

- 固定一个 `h`
- 输出四层 closure heatmap：
  1. `joint_feasible_ratio`
  2. `DG_best`
  3. `DA_best`
  4. `DT_best`

说明：

- 这是 closure 指标闭合关系的主表达图
- 论文级表达仍应优先使用这一版

---

### Phase4-C

入口：

- `tests/manual/manual_smoke_stage09_phase4_closure_heatmaps_hi.m`

状态：

- guarded feature

原因：

- 当前若只有单一高度层，则 `h-i` 图没有真实意义
- 程序会抛出：
  `plot_stage09_closure_heatmaps_hi:InsufficientHLevels`

---

## 四、Phase5

## 4.1 Full-height base builder

入口：

- `tests/manual/manual_smoke_stage09_phase5_build_fullheight_base.m`

作用：

- 先放开到 full 高度范围
- 构建真正多高度的 `base`
- 供后续 3D 堆叠图使用

---

## 4.2 Metric-wise stack3d-over-h plotter

核心函数：

- `src/analysis/plot_stage09_metric_stack3d_over_h.m`

支持指标：

- `joint`
- `DG`
- `DA`
- `DT`

图形语义：

- x 轴：`i`
- y 轴：`P`
- z 轴：按 `h` 堆叠
- 每张图只对应一个指标

因此：

- 同一张图内色标统一
- 物理意义单一
- 不再混合不同量纲指标

---

## 4.3 Phase5 plot smoke

入口：

- `tests/manual/manual_smoke_stage09_phase5_stack3d_plots.m`

作用：

- 基于 full-height `base`
- 输出四张 3D 图：
  - joint
  - DG
  - DA
  - DT

---

## 4.4 Phase5 suite

入口：

- `tests/manual/manual_smoke_stage09_phase5_suite.m`

作用：

1. 先构建 full-height base
2. 再统一输出四张 metric-wise stack3d-over-h 图

---

## 五、推荐执行顺序

```matlab
base5 = manual_smoke_stage09_phase5_build_fullheight_base();
out5p = manual_smoke_stage09_phase5_stack3d_plots(base5);

或直接：
MATLABout5 = manual_smoke_stage09_phase5_suite();

六、当前结论
当前 Stage09 的图形表达组织为：


平面 closure 图：表达指标闭合关系


3D stack 图：表达单一指标随高度的堆叠结构


这比“把不同物理意义指标强行画在同一张 3D 图中”更合理。
