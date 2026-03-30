# Stage09 Phase4 / Phase5 状态说明

## 一、当前范围

本阶段不再修改 Stage09 搜索主链，仅对已有 `base.cubes` 结果做 plot layer 和 manual smoke 组织层收口。

当前已完成内容包括：

- Phase4-A：多高度热图 plot 层
- Phase4-B：固定 `h` 的四层 closure heatmap
- Phase4-C：固定 `P` 的 `h-i` closure heatmap guarded feature
- Phase5：统一 manual smoke suite 与阶段说明收口

---

## 二、Phase4-A

入口：

- `tests/manual/manual_smoke_stage09_phase4_multih_heatmaps.m`

功能：

- 基于 `base.cubes.metric_over_h_i_P`
- 输出多高度热图 pack
- 不重跑搜索
- 输出目录落在：
  - `outputs/stage/stage09/figs/multih_heatmaps`
  - `outputs/stage/stage09/tables/multih_heatmaps`

说明：

- 该层是 Phase4 的 plot layer 基础件
- 已修复路径 fallback 问题
- 已修复 metric / closure index name 解析问题

---

## 三、Phase4-B

入口：

- `tests/manual/manual_smoke_stage09_phase4_closure_heatmaps.m`

功能：

- 固定一个 `h` 切片
- 输出四层 closure heatmap：
  1. `joint_feasible_ratio`
  2. `DG_best`
  3. `DA_best`
  4. `DT_best`

输出目录：

- `outputs/stage/stage09/figs/closure_heatmaps`
- `outputs/stage/stage09/tables/closure_heatmaps`

说明：

- 当前实验中该图已具备论文级表达价值
- 其中 `DT_best` 在当前数据下近似常值，这是结果特性，不是绘图错误

---

## 四、Phase4-C

入口：

- `tests/manual/manual_smoke_stage09_phase4_closure_heatmaps_hi.m`

目标：

- 固定一个 `P` 切片
- 输出 `h-i` 平面上的四层 closure heatmap

当前状态：

- **guarded feature**

原因：

- 当前 `base.cubes.index_tables.h` 只有单一高度层：
  - `h_idx = 1`
  - `h_km = 1000`

因此当前数据不满足真正的 `h-i` heatmap 前提。
若强行绘图，只会得到单行伪热图，表达无意义。

当前行为：

- 程序在检测到 `numel(h_vals) < 2` 时，抛出：

`plot_stage09_closure_heatmaps_hi:InsufficientHLevels`

这属于**预期行为**。

---

## 五、Phase5

入口：

- `tests/manual/manual_smoke_stage09_phase5_suite.m`

功能：

1. 复用 / 建立 cached base
2. 运行 Phase4-A
3. 运行 Phase4-B
4. 验证 Phase4-C guard 是否按预期触发

期望：

- 不重跑搜索
- Phase4-A / B 正常导出
- Phase4-C 输出 expected guard

---

## 六、推荐测试顺序

```matlab
base1 = manual_smoke_stage09_phase1_metric_views_cached();

out4A = manual_smoke_stage09_phase4_multih_heatmaps(base1);
out4B = manual_smoke_stage09_phase4_closure_heatmaps(base1);

try
    out4C = manual_smoke_stage09_phase4_closure_heatmaps_hi(base1);
catch ME
    fprintf('[EXPECTED GUARD] %s\n', ME.identifier);
end

out5 = manual_smoke_stage09_phase5_suite();

七、当前结论
到目前为止，Stage09 的 plot / smoke 组织层可视为阶段性收口：


A：完成


B：完成


C：guarded 收口


Phase5：用于统一验证和后续交付说明


后续若要真正启用 Phase4-C，需要先在搜索 / cube 构建层提供至少两个 h 切片。
