# 第五章最终结果总结

## 1. 当前实验链的最终组成

第五章当前已经完成并形成统一口径的主实验链包括：

- **R5**：bubble-predictive baseline
- **R9**：本文主方法（bubble-oriented closed-loop scheduling）
- **R10**：Li-style interval backend 同口径对照
- **统一诊断层**：将三种方法统一投影到第二章的 SC / DC / LoC 状态机，并补充 RMSE、V_r、M_G 等后验诊断图层

其中，R5 通过固定选星序列的 **Koopman diagnostic replay** 补齐了 RMSE、V_r、NIS 等诊断量，但不改变 R5 原有调度逻辑。

---

## 2. 统一诊断层下的状态占比结果

当前三种方法在 SC / DC / LoC 状态机下的占比如下：

| Phase | SC_ratio | DC_ratio | LoC_ratio |
|---|---:|---:|---:|
| R5 | 0.4353 | 0.1846 | 0.3801 |
| R9 | 0.4730 | 0.3113 | 0.2156 |
| R10 | 0.4663 | 0.1065 | 0.4272 |

这些结果表明：

1. **R9 的主要优势不是消除所有退化，而是显著减少 LoC。**
2. **R9 会把一大块原本会掉入 LoC 的时段，挽救成 DC。**
3. **R10 的特点是 DC 占比较低，但 LoC 占比较高。**
4. 因而，R10 更像“稳的时候更稳，但不稳时更容易直接掉链”；R9 更像“优先防止真正失托管”。

---

## 3. 三种方法的核心对比

### R5：bubble-predictive baseline

R5 提供了一个基于 bubble 预测的对照基线，其主要结果为：

- bubble steps = 282
- bubble fraction = 0.380054
- switch count = 12

在补充 Koopman replay 后，其诊断层 RMSE 为：

- mean RMSE pos ≈ 1.3037 km
- final RMSE pos ≈ 1.3515 km

R5 可以视为第五章后续方法比较的参考基线。

### R9：本文主方法

R9 的主要结果为：

- bubble steps = 160
- longest bubble = 149 s
- max bubble depth ≈ 7703.92
- switch count = 412
- mean RMSE pos ≈ 1.3245 km
- final RMSE pos ≈ 2.4537 km

统一诊断层结果显示：

- SC_ratio = 0.4730
- DC_ratio = 0.3113
- LoC_ratio = 0.2156

R9 的作用可以概括为：

> **优先压制硬失效 LoC，即便代价是系统更长时间停留在 DC。**

### R10：Li-style interval backend

R10 的主要结果为：

- bubble steps = 317
- longest bubble = 286 s
- max bubble depth ≈ 9755.56
- switch count = 7
- mean RMSE pos ≈ 1.1591 km
- final RMSE pos ≈ 1.3514 km

统一诊断层结果显示：

- SC_ratio = 0.4663
- DC_ratio = 0.1065
- LoC_ratio = 0.4272

R10 的作用可以概括为：

> **低切换、低 RMSE、平时稳定，但在关键区间更容易直接掉入 LoC。**

---

## 4. 当前得到的核心结论

### 结论 1：LoC 与 bubble 已经成功对齐

在当前统一诊断层下，LoC 与 bubble hard violation 已经实现一一对应：

- R5：LoC ratio ≈ bubble fraction
- R9：LoC steps = bubble steps = 160
- R10：LoC steps = bubble steps = 317

这说明第五章当前使用的 bubble，并不是一个脱离第二章的新量，而是第二章 LoC 的一个有效硬失败代理。

### 结论 2：R9 的本质是 “LoC -> DC” 转化

R9 并未把所有退化状态都消除，而是把大量原本会进入 LoC 的区间，转化成了 DC。  
这说明 R9 当前调度策略的最主要作用是：

> **避免真正失托管，而不是追求全程最稳。**

### 结论 3：R10 的本质是 “低 DC，但高 LoC”

R10 的 interval-hold 机制使其 RMSE 更低、切换更少，但一旦进入不利几何区间，更容易直接掉入 LoC。  
因此 R10 更适合作为：

- 平稳估计 / 低切换需求下的方法

而 R9 更适合作为：

- 关键窗口防失托管的方法

### 结论 4：为何直接基于 M_G 状态机做调度效果不好

当前统一诊断层结果支持如下解释：

- 第二章状态机中的 DC 表示“退化但尚未失效”
- 当前 R9 实际上大量利用了这部分 DC 区间，把系统从 LoC 拉回到 DC
- 若直接以 M_G / 状态机为主决策量，则会把大量 DC 也提前纳入强干预对象
- 从而导致可行域收缩过早，整体效果变差

因此，bubble 作为 LoC 级硬失败代理进入调度层，比直接使用完整状态机更合适。

---

## 5. 第二章到第五章的统一理解

当前实验结果支持如下统一表述：

1. **第二章**给出的是“轨迹管道 + 需求/供给表征 + SC/DC/LoC 状态机”的完整语义层。
2. **第五章**并未脱离第二章，而是进一步从中提炼出一个更适合进入调度优化器的硬失败代理，即 bubble / LoC proxy。
3. 因此，第五章不是在第二章之上“另起一套新理论”，而是在第二章语义层之上进行了执行化和代理化。

---

## 6. 当前建议进入正文的图表

建议正文保留：

1. **R5 / R9 / R10 的 SC/DC/LoC 占比柱状图**
2. **R9 与 R10 的 RMSE / bubble-state 图**
3. **R9 与 R10 的 V_r / M_G / FSM 图**
4. R5 作为基线，可保留一张代表性图或将部分图置于附录

NIS 图当前更适合作为诊断附图，不建议作为正文核心图。

---

## 7. 当前阶段结论

截至目前，第五章的**核心主实验链已经完成**，并已形成较清晰的最终结论口径：

- R9：更强的硬失败抑制能力
- R10：更优的平稳估计与低切换特性
- R5：参考基线
- bubble：第二章 LoC 的有效工程代理
- 统一诊断层：将第五章调度结果重新投影到第二章 SC / DC / LoC 状态机，实现了两章口径衔接

后续主要工作已不再是扩展新实验，而是：

- 最终图表筛选
- 正文与附录排布
- 理论衔接文字整理
