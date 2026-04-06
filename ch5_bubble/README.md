# ch5_bubble

第五章实验新主线目录。

## 1. 定位

`ch5_bubble/` 是第五章实验的新开发根目录。其目标不是继续在旧 `ch5_rebuild / Phase R` 上追加临时 runner，
而是建立一套可持续扩展的、面向多 case / Monte Carlo / 多策略统一对比的实验框架。

Phase B0 的任务是冻结工程骨架与约定，不追求算法完整性。
Phase B1 的任务是冻结 trajectory registry / trajectory sample / timeline diagnosis 的根接口。
Phase B1 当前已切换为真实轨迹路径：
Stage01 casebank -> Stage02 propagation engine -> ch5_bubble trajectory sample。

## 2. 开发原则

1. 轨迹管理器优先  
   先解决 trajectory sample / family / case 管理，再进入正式 compare。

2. 策略注册表统一  
   所有选星方法均通过统一入口调用，不允许 compare runner 手写大量 if-else。

3. 指标总线独立  
   bubble / lambda / RMSE / requirement / switch 等指标统一打包，不在策略层分散实现。

4. 图与计算分离  
   plot 只读取 traj sample / bundle，不在 plotting 层做核心计算。

5. 旧链冻结参考  
   `ch5_rebuild / Phase R` 仅作为参考，不再作为新主链继续追加开发。

## 3. 当前阶段

当前完成：
- Phase B0 工程骨架与约定
- Phase B1 真实轨迹管理器第一版（Stage01 + Stage02 engine）
- Phase B1.2 Stage02 轨迹来源诊断器第一版
- Phase B1-plot 真实轨迹三维绘图模块第一版

本阶段关键产物：
- `trajectory_manager/load_stage01_casebank_ch5b.m`
- `trajectory_manager/build_trajectory_registry.m`
- `trajectory_manager/resolve_trajectory_sample.m`
- `trajectory_manager/summarize_trajectory_sample.m`
- `trajectory_manager/diagnose_trajectory_timeline.m`
- `plots/plot_ch5b_trajectory_3d.m`
- `plots/plot_ch5b_trajectory_family_3d.m`
- `plots/export_ch5b_trajectory_family_3d.m`
- `runners/run_ch5b_phaseB1_registry_smoke.m`
- `runners/run_ch5b_phaseB1_plot_smoke.m`

## 4. B1 退出标准

- registry 来自真实 Stage01 casebank，而不是手工 stub；
- resolve 通过真实 Stage02 engine 生成 traj sample；
- 三维图绘制的是真实 `r_enu_km / r_eci_km / r_ecef_km`；
- 可以人工直接判断 nominal / heading / critical 的轨迹差异。

