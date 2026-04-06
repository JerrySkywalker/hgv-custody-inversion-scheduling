# ch5_bubble 架构说明

## 1. 总体结构

第五章新实验框架按如下四层组织：

Case / Trajectory Layer
-> Policy Layer
-> Metric Layer
-> Compare / Release Layer

### 1.1 Case / Trajectory Layer

职责：
- 管理 trajectory family / sample / case id
- 统一 nominal / critical / Monte Carlo 样本来源
- 负责 truth 元数据、timeline、终止原因诊断
- 为 case builder 提供规范输入

该层是整个系统的根，不允许在后续策略层临时拼接轨迹逻辑。

### 1.2 Policy Layer

职责：
- 在给定 case artifact 的前提下执行选星策略
- 输出统一 selection trace
- 不直接负责最终图表或论文解释

本层策略示例：
- static hold
- tracking greedy
- bubble predictive
- Li-style family

### 1.3 Metric Layer

职责：
- 给定 case + selection trace (+ filter trace)，统一计算指标
- 输出 metric bundle
- 不关心策略内部细节

本层指标示例：
- lambda metrics
- bubble metrics
- RMSE metrics
- requirement metrics
- switch/resource metrics

### 1.4 Compare / Release Layer

职责：
- 组织多策略、多 case、多 interval 的统一比较
- 输出图表、表格、论文发布包
- 不侵入底层策略实现

## 2. 分层依赖规则

允许依赖方向：

trajectory_manager -> case_builder -> policies -> metrics -> compare -> release

不允许反向依赖，例如：
- metrics 反向调用策略内部私有函数
- plotting 直接重算核心指标
- compare 直接绕过 registry 操作策略内部状态

## 3. 统一数据对象

B0 阶段先冻结以下对象名称，不要求全部实现完成：

### 3.1 trajectory_sample

建议字段：
- sample_id
- family_id
- case_label
- source_tag
- time
- truth
- dt
- n_steps
- terminal_reason
- metadata

### 3.2 case_artifact

建议字段：
- case_id
- trajectory_sample
- constellation
- sensor_profile
- sat_bank
- pair_bank
- config
- metadata

### 3.3 selection_trace

建议字段：
- policy_name
- case_id
- time
- selected_ids
- score
- candidate_count
- step_metadata
- summary

### 3.4 metric_bundle

建议字段：
- case_id
- policy_name
- lambda_series
- bubble_series
- rmse_series
- requirement_margin
- switch_metrics
- resource_metrics
- metadata

## 4. B0 冻结约定

1. compare runner 未来必须通过 registry 调策略；
2. plot 层未来只读 bundle；
3. 旧 `ch5_rebuild` 不做主开发；
4. B1 必须优先解决 trajectory registry 与 sample 解析。

