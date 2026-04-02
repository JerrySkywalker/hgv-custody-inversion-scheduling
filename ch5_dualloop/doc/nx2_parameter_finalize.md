# NX-2 参数定型收口

## 目标

基于 NX-2 第二轮的最小参数扫描，给出一个临时可用的状态机壳子默认参数集，并形成 markdown 收口材料，便于后续论文写作和工程基线冻结。

## 当前推荐参数

- `nx2_dwell_steps = 16`
- `nx2_guard_enable = false`
- `nx2_guard_ttl_steps = 8`

## 推荐理由

当前扫描表明：

1. `dwell` 已经有效，特别是在 `ref128` 场景下，能够压低切换数，同时保持 `q_worst_window` 不变，并略微改善 `outage_ratio`。
2. `guard_ttl_steps` 在当前实现下几乎没有灵敏度，继续细扫阈值意义不大。
3. `guard_enable` 当前实现更像弱抑制器，而不是强任务判据，因此本轮不建议默认开启。

## 当前工程判断

- 最小状态机壳子已接线成功。
- `dwell` 已初步证明有效。
- `guard` 目前还偏弱，下一阶段应升级为组合判据，而不是继续做 TTL-only 参数扫描。

## 下一步建议

进入下一阶段时，应优先考虑：

- 将 `guard` 从 TTL-only 升级为 `TTL + state upgrade`
- 或升级为 `TTL + M_G`
- 或升级为 `TTL + 连续坏窗口预警`

而不是继续扩大当前 TTL-only 的参数网格。
