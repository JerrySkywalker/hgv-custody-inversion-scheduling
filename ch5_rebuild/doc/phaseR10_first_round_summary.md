# R10 第一轮结果判读与与 Li 方法差异分析

## 1. 实验定位

R10 不是独立重建一套 Li 系统，而是在当前已经跑通的统一闭环框架内，仅将外层调度后端替换为 Li-style interval relay scheduling，从而与本文提出的 R9 方法在同一参数组合下进行直接比较。

统一条件包括：

- 同一目标轨迹：N01
- 同一固定星座：theta_star
- 同一资源规模：双星跟踪
- 同一 bubble 统计口径：centered_full_only
- 同一跟踪误差输出方式：闭环位置 RMSE
- 同一切换计数方式：switch count 仅记录，不进入当前优化目标

因此，R10 的比较重点不是“谁的整套系统更复杂”，而是：

- R9：rolling bubble-oriented scheduling
- R10：Li-style interval observability-oriented scheduling

---

## 2. Li 方法在当前壳层中的最小复现口径

根据 Li 等（2024）论文，relay tracking mode 的关键特征包括：

1. 整个任务由固定长度的 tracking intervals 组成；
2. 每个 interval 内先进行 coarse selection，再进行 refined selection；
3. refined selection 以 observability / information matrix 为核心，其中终端信息矩阵的 det(Y) 是主要选择依据；
4. 论文仿真中 tracking interval 取 30 s，且每个 interval 选 2 颗卫星。

因此，R10 在当前壳层中保留 Li 的以下本质：

- interval-based relay scheduling
- fixed pair within one interval
- coarse visibility support
- refined logdet(Y_interval) selection

但不照搬 Li 的 200 星 Walker 星座和独立仿真外壳，而是坚持与 R9 共享统一实验环境。

---

## 3. R9 与 R10 第一轮对比结果

统一 summary table 如下：

| policy | valid_steps | bubble_steps | bubble_time_s | longest_bubble_time_s | max_bubble_depth | mean_bubble_depth | switch_count | mean_rmse_pos_km | final_rmse_pos_km |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| R9-real_koopman_pipe_feedback | 742 | 160 | 160 | 149 | 7703.9 | 926.54 | 412 | 1.3245 | 2.4537 |
| R10-li_interval_backend | 742 | 317 | 317 | 286 | 9755.6 | 2279.3 | 7 | 1.1591 | 1.3514 |

---

## 4. 结果判读

### 4.1 R9 在空泡抑制上明显优于 R10

相较于 R10，R9 的优势非常清楚：

- bubble_steps：317 -> 160
- bubble_time_s：317 -> 160
- longest_bubble_time_s：286 -> 149
- max_bubble_depth：9755.6 -> 7703.9
- mean_bubble_depth：2279.3 -> 926.54

这说明 R9 的 rolling bubble-oriented 调度后端能够更有效地：

- 打断长时间连续空泡；
- 降低总失托管时长；
- 压低最坏窗口下的结构退化程度。

因此，如果论文的主目标是“持续托管能力”或“可观性空泡抑制”，那么当前结果明确支持 R9。

### 4.2 R10 在 RMSE 与低切换上明显优于 R9

与此同时，R10 在另外两个方面也有鲜明优势：

- switch_count：412 -> 7
- mean_rmse_pos_km：1.3245 -> 1.1591
- final_rmse_pos_km：2.4537 -> 1.3514

这说明 Li-style interval relay backend 的本性确实更偏向：

- interval 内更稳定的观测几何；
- 更低频率的 pair 重构；
- 更平滑的闭环跟踪误差表现。

这一点与 Li 原论文的主叙事一致：relay tracking mode 的优势之一正是较少姿态控制、较长跟踪弧段以及较好的 tracking accuracy。

---

## 5. 当前对比最重要的结论

R9 与 R10 并不是“谁全面优于谁”的关系，而是呈现出非常清晰的 tradeoff：

### R9 更适合：
- 压制可观性空泡；
- 强化 rolling worst-window 托管能力；
- 减少总 bubble time 与 longest bubble。

### R10 更适合：
- 降低位置 RMSE；
- 减少 pair 切换；
- 保持 interval-level tracking 的平稳性。

因此，这一轮实验首次在统一参数组合下，把两种方法的目标差异量化出来：

- Li-style 方法偏 interval observability / RMSE / fewer controls；
- 本文方法偏 rolling bubble suppression / sustained custody。

这正是第五章最有价值的一组对照结果。

---

## 6. 当前阶段可形成的论文口径

可以形成如下判断：

> 在统一闭环仿真框架下，Li-style interval relay scheduling 在跟踪精度和动作稀疏性方面更有优势，而本文提出的 rolling bubble-oriented scheduling 在持续托管与可观性空泡抑制方面显著更优。二者体现了不同任务目标下的 bubble–RMSE–switch tradeoff。

这一表述目前已有明确实验支撑。

---

## 7. 当前结论的边界

尽管本轮结果已经很有说明力，但仍需注意：

1. 当前 R10 仍是 Li-style 最小后端版本，而非全文逐式复刻；
2. 当前 R10 与 R9 共用统一内环，这样做是为了突出调度策略差异，而不是复刻 Li 的完整 ARUKF 系统；
3. 当前结果已足以支持第五章方法差异论证，但若要作为最终定稿结果，仍建议补一轮 very small R10 参数 smoke，确认 interval 长度等设置不会改变主要结论。

---

## 8. 下一步建议

建议进行 very small R10 参数 smoke，仅扫描少量 interval 相关参数，例如：

- interval_steps ∈ {20, 30, 40}
- min_support_ratio ∈ {0.5, 0.8}

优先观察：

- bubble_steps
- longest_bubble_time_s
- mean_rmse_pos_km
- final_rmse_pos_km
- switch_count

若扫描后仍保持“R10 RMSE 更优而 R9 bubble 更优”的基本格局，则可以认为第五章主对比结论已经稳定。
