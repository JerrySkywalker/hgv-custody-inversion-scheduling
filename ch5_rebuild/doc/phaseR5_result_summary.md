# Phase R5 实验结果口径整理

## 1. 本阶段目标

Phase R5 对应第五章主实验“前瞻补泡主线”。其目标不是证明方法在 mean RMSE 上全面优于 tracking 基线，而是证明：在相同双星资源约束下，显式面向未来窗口最弱方向的调度，能够进一步压缩可观性空泡的持续时间与平均严重程度，并且不以明显恶化 RMSE proxy 为代价。

按照第五章实验总计划，R5 的核心算法为

\[
\mathcal S_k^{(C)}=
\arg\max_{\mathcal S\subseteq\mathcal A_k}
\Big[
\min_{W\subset[t_k,t_k+T_h]}\lambda_{\min}(Y_W(\mathcal S))
-\lambda_1 C_{\mathrm{switch}}
-\lambda_2 C_{\mathrm{resource}}
\Big].
\]

当前工程实现采用：

- 固定真实星座 `theta_star`
- 真实 Stage02 轨迹 `N01`
- 真实 Stage03 可见性候选集
- 局部 horizon 未来窗口预测
- 切换惩罚 + 最小保持步数平滑

## 2. 与实验计划的对照结论

截至当前，Phase R5 已经完成了该阶段计划中的主线内容：

1. 已建立 `policy_bubble_predictive` 对应的真实调度主线。
2. 已完成 `predict_future_window_information` 与 `evaluate_candidate_bubble_gain` 的核心实现。
3. 已完成 `run_ch5r_phase5_bubble_predictive` 的主实验运行。
4. 已完成 `R3-real / R4-real / R5-real` 的正式 compare bundle。
5. 已补充 RMSE proxy 曲线，用于检查 R5 是否在精度 proxy 上不逊于 R4。

仍未完成的内容主要属于后续 Phase R6 及之后：

- 空泡到需求精度界限失守的直接后果链
- 更严格的物理 RMSE 对比
- 双环增强版、弱先验、轻量 MC

因此，当前可以判定：**Phase R5 主实验已按预期完成，且达到了“先把空泡存在—补泡有效—不明显牺牲精度 proxy”这条主链打穿的阶段目标。**

## 3. 当前结果摘要

当前对比结果如下：

- R3-real：`bubble_time_s = 622`，`switch_count = 0`
- R4-real：`bubble_time_s = 393`，`switch_count = 7`
- R5-real：`bubble_time_s = 194`，`switch_count = 58`

进一步地：

- `R5-real` 相比 `R4-real`，`bubble_time_s` 再减少 `199 s`
- `R5-real` 相比 `R3-real`，`bubble_time_s` 总共减少 `428 s`
- `R5-real` 的 `longest_bubble_time_s = 138`，显著短于 `R4-real = 339`
- `R5-real` 的 `mean_bubble_depth = 1404.9`，显著低于 `R4-real = 3654.2`
- `R5-real` 的 `mean_rmse_proxy = 0.006894`，略优于 `R4-real = 0.0077054`
- `R5-real` 的 `max_bubble_depth` 与 `R4-real` 基本一致，说明其主要收益体现在压缩持续时间与平均严重程度，而不是继续降低最坏极值

## 4. 阶段性物理解释

### 4.1 为什么 R5 优于 R4

R4 采用的是 tracking-oriented greedy，更关注当前时刻信息强度；R5 则显式面向未来 horizon 内的最弱窗口，因此更倾向于避免“当前看起来不错、未来窗口却即将塌陷”的双星选择。其直接效果就是：

- bubble 出现得更少
- 最长连续 bubble 被显著压缩
- 平均 bubble 深度更小

因此，R5 的主要价值不是“进一步压低最坏一个点的极值”，而是“显著提升托管连续性”。

### 4.2 为什么 switch_count 会高于 R4

R5 引入前瞻补泡，本质上更敏感于未来窗口退化，因此天然比 R4 更积极切换。当前通过：

- 增大 `lambda_sw`
- 加入 `min_hold_steps`
- 使用局部 horizon 预测

已经将切换次数从早期版本的 `401` 压缩到 `58`。这说明平滑约束是有效的，但也说明 R5 的代价仍高于 R4。这一特征在论文中应作为“代价—收益权衡”如实表述。

## 5. RMSE 问题的正式口径

### 5.1 为什么当前只能做 RMSE proxy 对比

当前工程中的 RMSE 曲线不是物理滤波 RMSE，而是 Fisher-based RMSE proxy：

\[
\mathrm{RMSE\ proxy}(k)=\sqrt{\frac{1}{\max(\lambda_{\min}(J_W(k)),\varepsilon)}}.
\]

它的作用是：

- 用于比较不同策略在窗口最弱方向上的信息强弱
- 用于检验 “补泡收益是否伴随精度 proxy 明显恶化”

它**不是**通过完整滤波器得到的真实位置 RMSE，因此不能直接写成“误差多少米/多少千米”。

### 5.2 什么时候才能做真正的 RMSE 对比

只有在以下条件全部具备时，才能做真正的 RMSE 对比：

1. **建立真实滤波闭环**：例如 EKF/UKF/信息滤波器，状态向量、状态转移、过程噪声、观测噪声都明确。
2. **把调度策略真正接入滤波器**：每个时刻选中的双星对决定实际观测输入，而不是只构成 Fisher proxy。
3. **定义统一的误差输出空间**：例如位置 RMSE、需求子空间投影 RMSE，或者关键托管变量 RMSE。
4. **有 truth 对照轨迹**：当前这一点已有真实 Stage02 轨迹，但还缺滤波估计轨迹与协方差递推闭环。
5. **明确 Monte Carlo 统计口径**：因为真正的 RMSE 通常需要多次随机仿真统计，而不是单条 deterministic 曲线。

也就是说，**真正的 RMSE 对比应在 Phase R6 之后，至少在完成“需求精度界限后果链 + 内环滤波闭环”后再开展。**

## 6. 当前可以写入论文的口径

建议当前 Phase R5 在论文中使用如下表述：

> 在固定真实星座与相同双星资源约束下，前瞻补泡调度相较于短视动态调度，进一步将 bubble 持续时间从 `393 s` 压缩至 `194 s`，并显著降低最长连续 bubble 时长与平均 bubble 深度；同时，在 Fisher-based RMSE proxy 口径下，未观察到明显的精度劣化，反而略有改善。这表明显式面向未来窗口最弱方向的调度机制能够有效抑制可观性空泡，并在不明显牺牲精度 proxy 的前提下提升托管连续性。

同时应保留一个限制性说明：

> 当前 RMSE 结果仍是 Fisher-based proxy，而非物理滤波 RMSE；真正的 RMSE 对比应在后续引入滤波闭环后开展。

## 7. 进入 Phase R6 的建议接口

下一阶段应围绕“空泡到需求精度界限失守的后果链”展开，建议顺序为：

1. 在当前 `R5-real` 结果基础上，建立 `P_r = C_r P C_r^T` 或其 proxy 的需求子空间误差表征；
2. 构造 `margin_req = \Gamma_req - \lambda_{\max}(P_r)`；
3. 将 `bubble_time / longest_bubble_time / mean_bubble_depth` 与 `requirement margin` 直接关联成图；
4. 在此之后，再考虑引入真实滤波闭环，进入“物理 RMSE 对比”阶段。

