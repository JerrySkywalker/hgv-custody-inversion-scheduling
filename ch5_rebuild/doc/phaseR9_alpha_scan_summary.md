# R9 参数扫描结果判读与临时主参数建议

## 1. 实验目的

本轮实验针对 R9 的唯一主参数 `alpha_tau` 做最小 smoke 扫描，考察其对以下指标的影响：

- bubble_steps
- bubble_time_s
- longest_bubble_time_s
- max_bubble_depth
- mean_bubble_depth
- switch_count
- mean_rmse_pos_km
- final_rmse_pos_km

同时，结合 compare bundle，将 R9 与 R4、R5 在统一 valid full-window 口径下进行对比。

---

## 2. compare bundle 结果概览

统一结果如下：

| policy | valid_steps | bubble_steps | bubble_time_s | longest_bubble_time_s | max_bubble_depth | mean_bubble_depth | switch_count | mean_rmse_pos_km | final_rmse_pos_km |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| R4-real_dynamic_pair | 742 | 342 | 342 | 342 | 10210.3 | 3189.3 | 6 | NaN | NaN |
| R5-real_predictive_pair | 742 | 282 | 282 | 278 | 7496.6 | 1421.7 | 12 | NaN | NaN |
| R9-real_koopman_pipe_feedback | 742 | 178 | 178 | 157 | 7703.9 | 950.45 | 283 | 1.3284 | 2.4728 |

### 判读

1. R9 相比 R4、R5，已经明显降低了 `bubble_steps` 与 `longest_bubble_time_s`。
2. R9 当前是三者中最强的空泡抑制方案。
3. R9 的代价是 `switch_count` 极高，说明其属于高频重构型策略。
4. R9 的 `max_bubble_depth` 尚未优于 R5，说明当前方法更擅长“打断长时间连续空泡”，而不是专门压制最坏单点深度。
5. compare bundle 中 R9 已统一到显式 tail mode 版本，`k>=772` 进入 `r9_tail_hold`，尾段 score 为 `NaN` 属于正常现象，表示该阶段不再使用正常评分口径。

---

## 3. alpha 参数扫描结果

扫描集合：

\[
\alpha \in \{0,\ 0.25,\ 0.5,\ 1,\ 2\}
\]

结果如下：

| alpha_tau | valid_steps | bubble_steps | bubble_time_s | longest_bubble_time_s | max_bubble_depth | mean_bubble_depth | switch_count | mean_rmse_pos_km | final_rmse_pos_km |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 742 | 247 | 247 | 155 | 7703.9 | 1082.6 | 557 | 1.3499 | 1.3401 |
| 0.25 | 742 | 174 | 174 | 157 | 7703.9 | 958.66 | 477 | 1.3046 | 1.3438 |
| 0.5 | 742 | 160 | 160 | 149 | 7703.9 | 926.54 | 412 | 1.3245 | 2.4537 |
| 1 | 742 | 178 | 178 | 157 | 7703.9 | 950.45 | 283 | 1.3283 | 2.4728 |
| 2 | 742 | 175 | 175 | 156 | 7561.7 | 940.42 | 251 | 1.3226 | 2.4726 |

---

## 4. 主要规律

### 4.1 alpha 从 0 增加到 0.5 时，空泡显著改善

- bubble_steps: 247 -> 174 -> 160
- longest_bubble_time_s: 155 -> 157 -> 149
- mean_bubble_depth: 1082.6 -> 958.66 -> 926.54

说明仅靠方向性供给主项不足以充分抑制空泡，引入未来违约比例惩罚后，策略显著增强了主动避泡能力。

### 4.2 alpha 继续增大到 1 或 2，并未继续改善总 bubble

- bubble_steps: 160 -> 178 -> 175

说明过大的未来违约比例权重会削弱当前最关键方向供给的效率。

### 4.3 alpha 越大，switch_count 总体越低

- 557 -> 477 -> 412 -> 283 -> 251

虽然当前 switch count 不进优化目标，但 alpha 本身已经间接影响了动作激进程度。

### 4.4 max_bubble_depth 对 alpha 不敏感

- alpha = 0, 0.25, 0.5, 1 时，max_bubble_depth 基本相同（7703.9）
- 只有 alpha = 2 时略降到 7561.7

说明当前 R9 的评分结构主要优化的是：

- bubble 总时长
- longest bubble
- mean bubble depth

而不是最坏单点深度。

---

## 5. 参数建议

### 5.1 若以空泡抑制为第一目标

推荐当前临时主参数：

\[
\boxed{\alpha = 0.5}
\]

理由：

- bubble_steps 最小
- bubble_time_s 最小
- longest_bubble_time_s 最小
- mean_bubble_depth 最小

这是当前最强的“空泡主参数”。

### 5.2 若希望兼顾更好的 RMSE 表现

推荐保留对照参数：

\[
\boxed{\alpha = 0.25}
\]

理由：

- bubble 表现已经明显优于 R5
- mean_rmse_pos_km 和 final_rmse_pos_km 更好
- 是一档更均衡的折中点

### 5.3 不建议作为当前主参数的取值

- `alpha = 0`：过于短视，bubble 明显偏多
- `alpha = 1`：可用，但整体不优
- `alpha = 2`：动作更保守、最坏深度略好，但总体 bubble 不占优

---

## 6. 当前阶段结论

1. R9 的方法主线已经成立，且明显优于 R4 / R5 的空泡抑制表现。
2. 当前参数扫描已经足以支持第五章临时主参数选择。
3. 当前建议：
   - 主结果参数：`alpha = 0.5`
   - 均衡对照参数：`alpha = 0.25`
4. 下一步可以进入 Li 方法的同口径对比设计。

---

## 7. 后续与 Li 方法对比的建议口径

后续与 Li 方法比较时，建议至少统一输出：

- bubble_steps
- bubble_time_s
- longest_bubble_time_s
- max_bubble_depth
- mean_rmse_pos_km
- final_rmse_pos_km
- switch_count

这样可以清晰地区分两类方法：

- Li：更偏 interval observability / RMSE / attitude control
- R9：更偏 rolling worst-window bubble suppression
