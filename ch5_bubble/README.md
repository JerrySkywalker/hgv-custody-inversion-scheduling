# ch5_bubble

第五章实验新主线目录。

## 1. 定位

`ch5_bubble/` 是第五章实验的新开发根目录。其目标不是继续在旧 `ch5_rebuild / Phase R` 上追加临时 runner，
而是建立一套可持续扩展的、面向多 case / Monte Carlo / 多策略统一对比的实验框架。

Phase B0 的任务是冻结工程骨架与约定，不追求算法完整性。

## 2. 开发原则

1. 轨迹管理器优先  
   先解决 trajectory sample / family / case 管理，再进入正式 compare。

2. 策略注册表统一  
   所有选星方法均通过统一入口调用，不允许 compare runner 手写大量 if-else。

3. 指标总线独立  
   bubble / lambda / RMSE / requirement / switch 等指标统一打包，不在策略层分散实现。

4. 图与计算分离  
   plot 只读取 bundle，不在 plotting 层做核心计算。

5. 旧链冻结参考  
   `ch5_rebuild / Phase R` 仅作为参考，不再作为新主链继续追加开发。

## 3. 当前阶段

当前完成：Phase B0 工程骨架与约定。

本阶段关键产物：
- `doc/architecture.md`
- `doc/naming_convention.md`
- `params/default_ch5b_params.m`
- `runners/run_ch5b_phaseB0_smoke.m`

## 4. 目录说明

- `doc/`：架构、命名、开发约定
- `params/`：默认参数、参数组装
- `trajectory_manager/`：轨迹族、sample、timeline 诊断
- `case_builder/`：标准 case artifact 组装
- `candidates/`：候选星对/星集构建
- `policies/`：各类选星策略
- `strategy_registry/`：统一策略注册与调度入口
- `filter/`：滤波或代理估计层
- `metrics/`：统一指标层
- `compare/`：统一比较逻辑
- `plots/`：绘图输出
- `runners/`：实验入口
- `analysis/`：诊断脚本
- `release/`：论文发布包导出

## 5. B0 退出标准

若满足以下条件，则 B0 可视为完成：

- 新目录结构已经建立；
- README、架构文档、命名规范文档已冻结；
- 默认参数入口可正常返回结构体；
- smoke runner 可在 MATLAB Desktop CLI 下成功执行；
- 后续 B1/B2 文件可直接按约定继续补齐。

## 6. 后续开发顺序

建议顺序：

B1 轨迹管理器  
B2 case builder / candidate builder  
B3/B4 策略注册表与统一 trace  
B5 统一指标层  
B6 空泡主线  
B7 Li 方法对比  
B8 interval 研究  
B9 多 case / MC  
B10 release

