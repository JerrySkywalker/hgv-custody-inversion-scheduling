# NX-3 第二轮：guard 对最终 selection 的门控作用

## 目标

并行实现两条 guard-action 路线，并比较它们对最终 selection 的影响：

- 方案 A：`freeze_selection`
- 方案 B：`degrade_mode`

## 两种方案的区别

### A：freeze selection
当 guard 不满足时，直接冻结上一时刻 `selected_ids`。

优点：
- 最直接
- 最容易压低最终切换

风险：
- 可能过于保守
- 容易把几何机会一起冻结掉

### B：degrade mode
当 guard 不满足时，不冻结，而是把当前 mode 降级：
- `trigger -> warn`
- `warn -> safe`

然后用降级后的 mode 重新选星。

优点：
- 更柔和
- 更贴近托管状态机语义

风险：
- 可能不如 A 那样强力压切换
- 但更可能保住托管质量

## 本轮判断目标

比较三组：

- `NX3-base`
- `NX3-A-freeze`
- `NX3-B-degrade`

观察：

- `q_worst_window`
- `outage_ratio`
- `switch_count`
- `applied_switch_count`
- `mean_rmse`

然后决定后续主线更适合 A 还是 B。
