# NX-4 第一轮：模板与局部几何 proposal 层重定位

## 目标

将模板与局部几何从“潜在主链增强器”重定位为“独立 proposal 层”。

本轮不直接改动主链 selection，只做：

- template library 构建
- current query feature 提取
- proposal pairs 排序
- 与当前 CK baseline 结果做 overlap 对照

## 为什么这样做

NX-3 已经说明，更强的在线动作门控并不一定带来更好的最终托管表现，因此当前更合理的方向不是继续增强硬干预，而是先把第四章静态知识作为独立推荐层挂出来。

## 本轮产物

- `apply_nx4_proposal_defaults.m`
- `build_nx4_template_proposal.m`
- `run_nx4_proposal_compare_smoke.m`

## 下一轮可能方向

如果 proposal 与 baseline overlap 较高，则可考虑：

- 作为 tie-break
- 作为 explanation layer
- 作为 warn/trigger 阶段的 soft proposal

而不直接进入 hard filter。
