# 第五章主线冻结说明

## 1. 冻结目的

本说明用于明确第五章后续不再继续扩展的 exploratory 路线，以及正式冻结的统一实验主线。

## 2. 当前正式主线

当前正式主线冻结为：

- `S`：静态保持基线法
- `T`：tracking-oriented dynamic
- `C`：custody-oriented single-loop
- `CK`：custody-oriented dual-loop Koopman
- `CK + NX2 dwell-final`

其中，`CK + NX2 dwell-final` 的当前推荐参数为：

- `nx2_dwell_steps = 16`
- `nx2_guard_enable = false`
- `nx2_guard_ttl_steps = 8`

## 3. 当前不再继续推进的路线

以下路线当前不再作为主线增强器继续推进：

### 3.1 Phase 8 reference prior 直接在线接入
当前结果未证明其稳定有效，且存在恶化主链表现的风险。

### 3.2 NX-3B degrade-mode
该路线已经证明会伤害几何质量和最终托管表现，因此不采纳。

### 3.3 NX-4 soft proposal online coupling
proposal-only 层有信息量，但在线 soft coupling 未能撬动主链 selection，因此当前不再继续作为在线增强器推进。

## 4. 当前保留但仅作辅助层的模块

以下模块保留，但其角色降级为辅助层：

- template/reference prior
- local geometry proposal
- proposal-only compare
- diagnostic / explanation outputs

## 5. 后续主任务

从本说明开始，第五章后续主任务冻结为：

1. 完成窗口长度主扫描（Phase 9）
2. 完成 release 图表包导出（Phase 10）
3. 对照论文草稿补齐正式写作所需图表与摘要

不再扩大 exploratory 技术路线。
