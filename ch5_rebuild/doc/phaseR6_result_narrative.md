# Phase R6 第二包：结果口径整理 + 写作表述固化

## 1. 本阶段定位

Phase R6 的目标不是继续优化 bubble 指标本身，而是回答一个更强的问题：

> bubble 的出现是否会进一步对应到任务侧的需求风险上升，进而说明“空泡”不是自定义内部指标，而是与托管需求后果直接相关的结构性现象。

按照第五章实验总计划，R6 的理论目标应当是建立如下后果链：

\[
\lambda_{\min}(Y_W)\downarrow
\Rightarrow
\lambda_{\max}(P_r)\uparrow
\Rightarrow
\lambda_{\max}(P_r)>\Gamma_{\mathrm{req}}
\]

其中 \(P_r=C_rPC_r^\top\) 为需求子空间投影协方差，\(\Gamma_{\mathrm{req}}\) 为需求精度界限。

但当前已经完成的 `R6-real` 还不是这一“最终版”后果链，而是一个 **minimal real-line proxy version**。因此，本阶段的写作口径必须明确区分：

- **已经证明的内容**
- **尚未严格证明、只能作为合理 proxy 解释的内容**

---

## 2. 当前 R6-real 的方法设计

### 2.1 当前使用的信息量

当前 R6-real 仍建立在前面 R4/R5 使用的 rolling-window Fisher 信息矩阵之上，核心量为：

\[
Y_W(t)
\]

以及其最弱方向指标：

\[
\lambda_{\min}(Y_W(t))
\]

其中，当

\[
\lambda_{\min}(Y_W(t)) < \gamma_{\mathrm{req}}
\]

时，认为该时刻对应窗口发生 bubble。

### 2.2 当前 requirement-risk proxy 的定义

由于当前尚未建立闭环滤波器与真实需求子空间投影协方差 \(P_r\)，因此 R6-real 采用最小 proxy 映射：

\[
\text{req\_risk\_proxy}(t) = \frac{1}{\lambda_{\min}(Y_W(t))}
\]

并定义对应阈值 proxy：

\[
\text{req\_threshold\_proxy} = \frac{1}{\gamma_{\mathrm{req}}}
\]

于是有：

\[
\lambda_{\min}(Y_W(t)) < \gamma_{\mathrm{req}}
\quad\Longleftrightarrow\quad
\text{req\_risk\_proxy}(t) > \text{req\_threshold\_proxy}
\]

进一步定义需求裕度 proxy：

\[
\text{req\_margin\_proxy}(t)=
\text{req\_threshold\_proxy}
-
\text{req\_risk\_proxy}(t)
\]

因此：

- 若 `req_margin_proxy > 0`，表示当前需求风险 proxy 未越界
- 若 `req_margin_proxy < 0`，表示当前需求风险 proxy 已越界

### 2.3 当前图示的含义

当前 R6-real 输出两类图：

#### 图 A：Bubble to Requirement-Risk Chain

该图同时展示：

- 左轴：\(\lambda_{\min}(Y_W)\) 与 \(\gamma_{\mathrm{req}}\)
- 右轴：`req_risk_proxy` 与 `req_threshold_proxy`

其作用是展示：

> 当窗口信息下界跌破 bubble 阈值时，需求风险 proxy 是否同步上穿 requirement threshold proxy。

#### 图 B：Requirement Margin Proxy vs Bubble

该图同时展示：

- 左轴：`req_margin_proxy`
- 右轴：`bubble flag`

其作用是展示：

> bubble 的发生是否与需求裕度 proxy 失守在时间上同步出现。

---

## 3. 当前实验结果

本阶段 summary table 的核心结果为：

### R4-real dynamic pair

- req_violation_steps = 393
- req_violation_time_s = 393
- req_violation_fraction = 0.49064
- min_margin_proxy = -0.0028301
- mean_margin_proxy = -1.8549e-05
- bubble_req_coincidence_ratio = 1

### R5-real predictive pair

- req_violation_steps = 194
- req_violation_time_s = 194
- req_violation_fraction = 0.2422
- min_margin_proxy = -0.0028301
- mean_margin_proxy = -5.5219e-06
- bubble_req_coincidence_ratio = 1

---

## 4. 结果解释

### 4.1 已经可以明确成立的结论

#### 结论一：R5 在需求风险 proxy 口径下优于 R4

R5-real 将 requirement-risk violation time 从 R4-real 的 393 s 压缩到 194 s，下降 199 s，约减少 50.6%。

这表明：

> R5 的收益不只体现在 bubble 时间本身，也同步体现在需求风险 proxy 违规时间上。

因此，当前结果已经足以支持：

> 前瞻补泡调度不仅减少了空泡持续时间，也减少了需求侧风险 proxy 的越界持续时间。

#### 结论二：bubble 与 requirement-risk violation 在当前口径下完全同步

`bubble_req_coincidence_ratio = 1` 对 R4 与 R5 都成立。

这说明：

> 在当前 proxy 定义下，bubble 的发生与 requirement-risk violation 的发生时间上完全一致。

这证明当前 R6-real 已经实现了“bubble → requirement-risk”这一最小后果链映射。

#### 结论三：R5 改善了平均意义下的 requirement margin，但没有改善最坏极值

R4 与 R5 的 `min_margin_proxy` 完全相同，说明：

- 最坏 requirement-risk 极值并未改善

但 `mean_margin_proxy` 从

- R4：-1.8549e-05

改善到

- R5：-5.5219e-06

说明：

- R5 在整体平均意义下的需求裕度更好
- 其主要收益仍然是减少“越界持续时间”和“平均越界程度”
- 而不是抬升“最坏那个时刻”的极值

这一现象与前面 Phase R5 的结果完全一致：

- `bubble_time_s` 明显下降
- `mean_bubble_depth` 明显下降
- `max_bubble_depth` 基本未变

因此，R6 的结果与 R5 是互相印证的。

---

## 5. 当前结果“可以说到哪里”

当前 R6-real 可以稳定支持以下写法：

### 可直接写入论文正文的表述

> 基于真实滚动窗口 Fisher 信息矩阵，本文进一步构建了从可观性空泡到需求风险 proxy 的最小后果链。结果表明，R4-real 的需求风险违规时间为 393 s，而 R5-real 将其压缩到 194 s；同时，bubble 与需求风险违规在时间上完全同步，说明当前定义下的可观性空泡确实对应于需求侧风险上升，而非孤立的内部指标现象。

### 可作为图表解读的表述

> R5 的收益不仅表现为 bubble 的减少，也表现为 requirement-risk violation time 的同步下降；但这种改善主要体现在平均裕度和持续时间层面，而非最坏时刻的极值层面。

---

## 6. 当前结果“不能说到哪里”

以下说法在当前阶段 **不能直接写**，否则会超出当前 R6-real 的证据边界。

### 不能直接说一：已经证明了真实需求精度界限失守

当前还没有真正建立：

\[
P_r=C_rPC_r^\top
\]

也没有真正验证：

\[
\lambda_{\max}(P_r) > \Gamma_{\mathrm{req}}
\]

所以不能写成：

> “本文已经严格证明 bubble 会导致需求精度界限失守。”

当前更准确的写法应是：

> “本文在真实 Fisher 主线上建立了从 bubble 到 requirement-risk proxy violation 的最小后果链。”

### 不能直接说二：R6 已经是最终的任务后果证明

当前 R6-real 还是 proxy 版，而不是闭环滤波协方差版。

所以不能写成：

> “R6 已经完整闭合了从观测退化到任务失效的全部链条。”

更准确的说法应是：

> “R6 当前完成的是最小可运行的后果链映射，为后续闭环滤波协方差版分析提供依据。”

### 不能直接说三：当前 requirement-risk proxy 就是真实物理需求误差

当前 requirement-risk proxy 只是：

\[
1/\lambda_{\min}(Y_W)
\]

的映射形式，不是任务需求空间中的真实误差量。

---

## 7. 当前 R6 在第五章中的最合理定位

当前 Phase R6 最合理的定位不是“最终理论证明”，而是：

> **第五章主实验链条中的最小后果链支撑环节。**

它的作用是：

1. 回答“bubble 是否只是内部指标”的质疑  
2. 说明 Phase R5 的收益具有任务侧 proxy 含义  
3. 为后续真正的滤波闭环与需求子空间协方差分析留出接口

因此，在章节结构上，R6 当前可以作为：

- R5 之后的后果链说明
- R7/R8/R9 之前的机制闭环补充
- 但不应被写成最终严格式证明

---

## 8. 推荐写作口径（可直接改写到论文）

下面给出一段适合后续整合到论文中的口径草稿：

> 为说明可观性空泡并非仅是内部信息量指标，本文在真实滚动窗口 Fisher 信息主线上，进一步构建了从空泡到需求风险 proxy 的最小后果链。具体而言，基于窗口最弱方向信息下界 \(\lambda_{\min}(Y_W)\)，定义 requirement-risk proxy 为其倒数，并将 bubble 阈值 \(\gamma_{\mathrm{req}}\) 映射为对应的需求阈值 proxy。实验结果表明，R4-real 的需求风险违规时间为 393 s，而 R5-real 将其压缩到 194 s；同时，bubble 与需求风险违规在时间上完全同步，说明当前意义下的可观性空泡确实对应于需求侧风险上升。需要指出的是，当前结果仍属于 proxy 版后果链分析，尚未进入闭环滤波协方差投影 \(P_r=C_rPC_r^\top\) 的最终需求精度界限证明阶段。因此，本阶段的结论应理解为：本文已经在真实 Fisher 主线上建立了 bubble 与 requirement-risk violation 之间的直接映射，而更强的需求后果证明仍有待后续闭环滤波分析完成。

---

## 9. 当前阶段总结

### 已完成

- 建立了 bubble 到 requirement-risk proxy 的最小后果链
- 证明了 R5 在 requirement-risk violation time 上优于 R4
- 证明了 bubble 与 requirement-risk violation 在当前 proxy 口径下完全同步
- 固化了当前阶段可说与不可说的边界

### 尚未完成

- 闭环滤波协方差传播
- 需求子空间投影协方差 \(P_r\) 的真实构造
- 基于 \(\lambda_{\max}(P_r)\) 与 \(\Gamma_{\mathrm{req}}\) 的最终需求界限失守证明

因此，Phase R6 当前已具备论文阶段性写作价值，但仍应明确其 proxy 性质。

