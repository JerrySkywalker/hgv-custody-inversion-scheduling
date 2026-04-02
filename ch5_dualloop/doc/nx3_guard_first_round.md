# NX-3 第一轮：组合 guard 落地

## 目标

将 NX-2 中效果偏弱的 TTL-only guard 升级为最小组合 guard：

- TTL
- state upgrade
- M_G proxy
- bad-window proxy

## 本轮范围

本轮不碰 template / proposal 层，只升级状态机中的在线 guard 判据。

## 第一轮工程落点

新增：

- `package_nx3_guard_signals.m`
- `should_switch_under_guard_nx3.m`
- `apply_nx3_guard_defaults.m`

并在 `policy_custody_dualloop_koopman.m` 中接入。

## 当前预期

若 NX-3 成功，应该看到：

- `guard` 不再只是 TTL-only 的弱抑制器
- 在部分场景下，`switch_count`、`applied_switch_count`、`outage_ratio` 出现与 NX-2 不同的变化
- 即便结果仍较弱，也能说明下一阶段真正该增强的是 `guard` 定义，而不是继续扫 TTL 参数
