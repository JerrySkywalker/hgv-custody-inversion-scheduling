# WS-5 收口总结：模板先验驱动的参考选择与候选筛选机制

## 1. 目标与定位

WS-5 的目标不是继续沿用“加性先验分数”的旧路线，而是将结构先验真正接入到第五章双层闭环（dual-loop）调度链中，使其通过：

1. **reference selection**（参考结构选择）
2. **candidate filtering**（候选集合筛选）

来影响 outerB 的候选搜索空间与最终选择结果，而不是简单在 baseline objective 外再附加一个可能共线的 bonus 项。

经过 WS-1 至 WS-5-R5 的连续开发与验证，当前这条“模板先验 → 参考结构 → 候选筛选 → outerB baseline 打分”的方法链已经形成闭环，可视为第五章实验工程中的一条稳定支线。

---

## 2. 当前工程实现边界

截至 WS-5-R5，已经完成的内容包括：

- local-frame 几何特征提取
- prototype-based 模板库原型化
- template-guided reference selection 接入
- template-guided candidate filtering 接入
- 单时刻 / 多时刻效果量化
- `topK × library_pair_cap` 敏感性扫描
- 参数定型与导出图表生成

尚**未**完成或**暂不纳入当前收口范围**的内容包括：

- full prior objective 直接改写 baseline scoring
- 更复杂的聚类模板库
- 时间跨窗模板迁移
- 全量主流程 Phase 系列的正式耦合与大规模回归测试

因此，当前收口结论应理解为：

> WS-5 已完成“结构先验机制接入与有效性验证”，但尚未扩展为 fully integrated final production branch。

---

## 3. 关键实验结论

### 3.1 reference-only 当前作用偏弱

在多轮实验中，`reference_only` 相比 baseline：

- 在 `ref128` 场景中，`ratio_changed_B_vs_A = 0`
- 在 `stress96` 场景中，`ratio_changed_B_vs_A = 0`

说明仅靠模板驱动的 `ref_ids` 变化，当前还不足以单独改写 outerB 最终 argmin。  
因此，模板先验当前最有效的作用方式不是“只改参考结构”，而是与候选筛选联动。

---

### 3.2 candidate filtering 是当前真正生效的结构先验入口

在 `ref128` 场景中：

- `reference_plus_filter` 相比 baseline 的决策改写比例达到 `1.0`
- 即在所扫描时间窗内，模板筛选在全部有效时刻都改写了最终选择

在 `stress96` 场景中：

- 模板筛选始终能够压缩搜索空间
- 但是否改写最终选择，对 `topK` 与模板库规模敏感

因此当前可以明确得到：

> 结构先验的主效应不是“直接修正分数”，而是“先约束候选搜索空间，再由 baseline objective 在压缩后的结构化候选子空间中做选择”。

---

### 3.3 两个场景的功能定位不同

#### `ref128`
可视为**强改决策场景**：

- filtering 对最终选择有持续、稳定、系统性的改写作用
- 适合用于展示“模板筛选确实改变 outerB 决策”的正例

#### `stress96`
可视为**参数敏感场景**：

- filtering 的主要作用首先体现为压缩搜索空间
- 只有在更激进参数（如较小模板库、较小 topK）下，才更可能改写最终决策
- 适合用于展示“模板筛选效果依赖参数区间”的反例/边界例

这两个场景共同构成了一个较完整的验证对照：

- `ref128`：说明机制“能改决策”
- `stress96`：说明机制“并非无条件改决策，而是存在参数敏感区”

---

## 4. 参数定型结论

### 4.1 三档参数口径

为便于后续写作与汇报，固定如下三档：

- **Aggressive**：`topK = 2`, `library_pair_cap = 5`
- **Balanced**：`topK = 4`, `library_pair_cap = 10`
- **Conservative**：`topK = 8`, `library_pair_cap = 20`

### 4.2 推荐默认参数

当前推荐默认参数统一采用：

- `topK = 4`
- `library_pair_cap = 10`

原因如下：

#### 对 `ref128`
- 保持完整改决策能力
- 避免 `topK=2` 的过度激进筛选
- 相比更宽松配置，仍保持较强压缩率与结构作用

#### 对 `stress96`
- 保持稳定搜索空间压缩
- 避免 aggressive 配置带来的“过强决策强迫”
- 作为默认参数更稳妥，适合作为 Phase 系列回接前的默认工作点

因此，`balanced = (4, 10)` 可作为当前 WS-5 收口后的**默认工程口径**。

---

## 5. 图表导出状态

WS-5-R5 已完成一套面向人工判读与后续写作的图表导出，主要包括：

- decision change vs baseline
- decision change vs reference-only
- compression ratio
- kept candidate count
- profile map

这些图表已经足以支撑：

1. 内部阶段性汇报
2. 第五章实验结果的图示备份
3. 后续 Phase 系列回接前的参数口径说明

当前图表已达到“可用”状态。  
若后续需要写入论文正文，可再做一次轻量润色（字体、标题、矢量导出、图例精简），但这不再属于 WS-5 主体开发范畴。

---

## 6. 为什么现在选择收口

当前不再继续在 WS-5 内部深入的原因有三点：

### 6.1 机制链已经闭环
从特征提取、模板库、参考结构选择到候选筛选，整条路径已经打通，并且在实验上产生了可观测差异。

### 6.2 主要问题已从“机制是否成立”转为“如何接回主流程”
现在继续在 WS-5 内部做更多微调，收益开始下降。  
更关键的问题已经变成：

- 如何将这套默认参数与机制，正式接回 Phase 系列主流程
- 如何在更大尺度的 Phase 实验中检验它的收益

### 6.3 当前参数口径已经足以支持下一阶段开发
`balanced = (4,10)` 这一工作点已经足够作为默认配置使用，不需要再为了“找更优参数”而继续停留在分析支线中。

因此，从工程推进角度，WS-5 当前选择收口是合理的。

---

## 7. 回到 Phase 系列开发的衔接建议

WS-5 收口后，建议正式回到 Phase 系列开发。  
推荐衔接顺序如下：

### Phase 衔接建议 1：先接入 Phase08
优先将当前默认参数：

- `template_filter_topk = 4`
- `library_pair_cap = 10`

以**可开关选项**的方式接入 Phase08 相关入口，而不是立即替换 baseline 逻辑。  
目标是先形成：

- baseline Phase08
- Phase08 + reference selection
- Phase08 + reference selection + candidate filtering

三种可对比配置。

### Phase 衔接建议 2：保留旧逻辑回退路径
在 Phase 系列回接过程中，必须保留：

- `prior_enable = false`
- `template_filter_enable = false`

的纯 baseline 路径，确保后续回归测试与对照实验可做。

### Phase 衔接建议 3：优先做“少量典型场景回归”
回接初期不建议直接全量大扫描，而是先选：

- `ref128`
- `stress96`

两类代表场景做 Phase 级回归，确认：
- 逻辑接入正确
- 结果口径稳定
- 输出目录与日志行为正常

### Phase 衔接建议 4：把 WS-5 作为“可插拔模块”，不要深埋
建议将 WS-5 当前形成的关键部件视为一个独立模块，而不是在 Phase 主流程中写死。至少应保持以下层次清晰：

- local-frame feature extraction
- template library build / load
- reference matching
- candidate filtering

这样后续无论继续迭代模板机制，还是切回 baseline，都不会破坏 Phase 主链。

---

## 8. 最终收口结论

截至 WS-5-R5，可以正式给出如下收口结论：

> WS-5 已完成从“结构先验概念验证”到“可稳定运行的工程机制”的过渡。  
> 当前最有效的结构先验入口，不是 additive prior，而是“template-guided reference selection + candidate filtering”的组合。  
> 在 `ref128` 场景中，该机制能够稳定改写 outerB 最终选择；在 `stress96` 场景中，该机制稳定压缩搜索空间，并在特定参数区间内具备改写决策的能力。  
> 基于当前多轮实验与敏感性扫描结果，推荐默认参数固定为：
>
> - `template_filter_topk = 4`
> - `library_pair_cap = 10`
>
> 因此，WS-5 现阶段可以正式收口，后续开发重点应转向 Phase 系列主流程回接与回归验证。
