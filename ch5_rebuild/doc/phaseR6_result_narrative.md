# Phase R6 结果口径整理（修正版）

## 1. 本阶段定位

Phase R6 的目标不是继续优化 bubble 指标本身，而是建立一个**最小 real-line 后果链**，回答：

> bubble 的出现是否会同步对应到任务侧 requirement-risk proxy 的越界，从而说明“空泡”不是孤立内部指标，而与需求风险 proxy 上升一致。

当前 R6 仍不是完整闭环协方差证明链，而是一个 **minimal monotone proxy bridge**。

---

## 2. 当前方法的严格口径

当前 R6 使用的核心量仍来自滚动窗口 Fisher 信息矩阵：

\[
Y_W(t)
\]

以及其最弱方向指标：

\[
\lambda_{\min}(Y_W(t))
\]

Bubble 判据为：

\[
\lambda_{\min}(Y_W(t)) < \gamma_{\mathrm{req}}
\]

当前 requirement-risk proxy 定义为：

\[
\text{req\_risk\_proxy}(t)=\frac{1}{\lambda_{\min}(Y_W(t))}
\]

对应阈值 proxy 为：

\[
\text{req\_threshold\_proxy}=\frac{1}{\gamma_{\mathrm{req}}}
\]

因此：

\[
\lambda_{\min}(Y_W(t))<\gamma_{\mathrm{req}}
\iff
\text{req\_risk\_proxy}(t)>\text{req\_threshold\_proxy}
\]

这说明当前 R6 使用的是与 bubble 判据**单调等价**的 requirement-risk proxy。

---

## 3. 当前结果可以支撑什么

当前 R6 可以支撑以下结论：

1. R5 相比 R4，不仅减少了 bubble 时间，也同步减少了 requirement-risk proxy 违规时间。
2. R5 相比 R4，改善了平均意义下的 requirement margin proxy。
3. 当前 bubble 与 requirement-risk proxy violation 的时间重合，是由同一 rolling-window 信息指标经单调变换得到的，因此它可以作为 **sanity check**，但不能被表述为独立的闭环需求链证明。

---

## 4. 当前结果不能支撑什么

当前 R6 还不能直接证明：

\[
P_r=C_rPC_r^\top
\]

意义下的真实需求精度界限失守，因为当前并未引入闭环滤波协方差及需求子空间投影。

因此，R6 当前最准确的写法应是：

> 本阶段建立了从 bubble 到 requirement-risk proxy violation 的最小单调桥接，而非完整协方差投影需求链证明。

---

## 5. 当前阶段建议写作位置

- 可进入第五章正文，作为“bubble 具有需求侧后果”的最小证据。
- 但需明确标注：当前 requirement-risk 仍为 proxy，不是最终闭环协方差版本。
