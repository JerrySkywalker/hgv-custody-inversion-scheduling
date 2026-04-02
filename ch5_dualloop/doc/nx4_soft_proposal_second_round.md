# NX-4 第二轮：soft proposal 耦合

## 目标

在不进行 hard filter 的前提下，将 NX-4 proposal 层以弱 bonus / tie-break 的方式耦合进当前 CK 主链。

## 本轮原则

- 不替代 baseline selection
- 不强制过滤候选
- 只在 `warn / trigger` 模式下启用
- 只对 proposal top-k 候选给小 bonus

## 为什么这样做

第一轮已经表明：

- `ref128` 上 proposal top-1 可直接命中 baseline
- `stress96` 上 baseline 虽未被 top-1 命中，但已经落在 proposal top-k 中

因此当前最合理的增强方式是 soft proposal，而不是 hard filter。

## 本轮判断目标

比较：

- `NX4-base`
- `NX4-soft`
- `NX4-proposal-only`

重点观察：

- `q_worst_window`
- `outage_ratio`
- `switch_count`
- `applied_switch_count`

如果 soft proposal 只带来轻微、可控的 selection 调整，同时不损伤托管质量，则说明 NX-4 可以继续推进。
