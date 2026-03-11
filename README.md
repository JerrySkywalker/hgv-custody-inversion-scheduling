# CPT4 Disk Fresh

博士论文第四章仿真实验的 MATLAB 工程，采用分 Stage、分 Step 的持续开发方式。每个 Stage 的入口脚本位于 `stages/`，一键运行脚本位于 `run_stages/`。

## 环境要求

- MATLAB R2016b 或更高版本（建议 R2020a+，部分 Stage 使用 `parfeval` 等并行接口）

## 目录结构

```
cpt4_disk_fresh/
├── README.md                 # 本说明
├── startup.m                 # 工程路径与 results 目录初始化，各 Stage 入口前需先运行
├── params/
│   └── default_params.m      # 默认配置（路径、几何、时间、Stage01–08 参数等）
├── stages/                   # 各 Stage 的代码入口（按步骤拆分的 .m 脚本）
│   ├── stage00_bootstrap.m
│   ├── stage01_scenario_disk.m
│   ├── stage02_hgv_nominal.m
│   ├── stage03_visibility_pipeline.m
│   ├── stage04_window_worstcase.m
│   ├── stage05_nominal_walker_search.m
│   ├── stage05_plot_nominal_results.m
│   ├── stage05_analyze_pareto_transition.m
│   ├── stage06_define_heading_scope.m
│   ├── stage06_build_heading_family_physical_demo.m
│   ├── stage06_heading_walker_search.m
│   ├── stage06_compare_with_stage05.m
│   ├── stage06_plot_heading_results.m
│   ├── stage06_batch_heading_runs.m    # 可选：多组航向批量运行
│   ├── stage07_select_reference_walker.m
│   ├── stage07_define_critical_scope_refwalker.m
│   ├── stage07_scan_heading_risk_map.m
│   ├── stage07_select_critical_examples.m
│   ├── stage07_define_paper_plot_scope.m
│   ├── stage07_plot_paper_subset.m
│   ├── stage07_plot_critical_geometry.m
│   ├── stage07_write_paper_figure_notes.m
│   ├── stage08_define_window_scope.m
│   ├── stage08_scan_representative_cases.m
│   ├── stage08_scan_casebank_stats.m
│   ├── stage08_scan_smallgrid_search.m
│   ├── stage08_boundary_window_sensitivity.m
│   └── stage08_finalize_window_selection.m
├── run_stages/               # 一键运行脚本（按顺序调用 stages/ 中对应入口）
│   ├── run_stage00_bootstrap.m
│   ├── run_stage01_scenario_disk.m
│   ├── run_stage02_hgv_nominal.m
│   ├── run_stage03_visibility_pipeline.m
│   ├── run_stage04_window_worstcase.m
│   ├── run_stage05_nominal_walker.m
│   ├── run_stage06_heading_walker.m
│   ├── run_stage07_critical_geometry.m
│   ├── run_stage08_window_selection.m
│   └── run_all_stages.m      # 全流程 Stage00 -> Stage08
├── src/                      # 公共源码（几何、目标、传感、星座、窗口、搜索等）
├── results/                  # 运行输出（由 startup 创建）
│   ├── cache/                # 各 Stage 的 .mat 缓存
│   ├── logs/                 # 日志
│   ├── figs/                 # 图形
│   ├── tables/               # 表格 CSV
│   └── bundles/
├── deliverables/             # 里程碑与导出（若存在）
└── (其他如 paper/, tests/ 等按需)
```

## 各 Stage 含义概览

| Stage | 含义 | 主要输出 |
|-------|------|----------|
| **Stage00** | 项目引导与环境自检 | 路径与目录、默认配置、日志与 cache 自检 |
| **Stage01** | 保护盘场景与案例库 | casebank（nominal/heading/critical）、场景图 |
| **Stage02** | HGV 标称轨迹 | trajbank（各族轨迹 ENU/ECEF/ECI）、汇总与图 |
| **Stage03** | 可见性管线 | 单层 Walker、satbank、visbank（可见性矩阵） |
| **Stage04** | 时间窗最坏情况 | winbank、gamma_req 校准、谱与 margin 统计 |
| **Stage05** | 标称族 Walker 搜索与后处理 | 网格搜索 cache、可行表、Pareto 与倾角前沿图 |
| **Stage06** | 航向族 Walker 搜索与对比 | 航向族、搜索与 Stage05 对比、结果图 |
| **Stage07** | 临界几何与论文图 | 参考 Walker、风险图、选例、论文子集图与图注 |
| **Stage08** | 时间窗扫描与窗选型 | Tw 网格、代表案例/案例库/小网格/边界敏感度、最终窗推荐表与图 |

各 Stage 内部步骤的详细说明见 `run_stages/run_stageXX_*.m` 文件头部注释。

## 快速运行说明

1. **将工程根目录设为 MATLAB 当前目录**  
   例如：`cd('C:\...\cpt4_disk_fresh')`

2. **运行方式任选其一：**
   - **全流程（Stage00 到 Stage08 顺序执行）**
     ```matlab
     run_stages/run_all_stages
     ```
   - **只跑某一 Stage**（需已具备该 Stage 所需的前序 cache）
     ```matlab
     run_stages/run_stage00_bootstrap
     run_stages/run_stage01_scenario_disk
     run_stages/run_stage02_hgv_nominal
     run_stages/run_stage03_visibility_pipeline
     run_stages/run_stage04_window_worstcase
     run_stages/run_stage05_nominal_walker
     run_stages/run_stage06_heading_walker
     run_stages/run_stage07_critical_geometry
     run_stages/run_stage08_window_selection
     ```

3. **依赖关系**  
   - Stage00：无依赖，可最先运行。  
   - Stage01：无（或先跑 Stage00 初始化目录）。  
   - Stage02：依赖 Stage01 的 cache。  
   - Stage03：依赖 Stage02。  
   - Stage04：依赖 Stage03。  
   - Stage05：依赖 Stage04。  
   - Stage06：依赖 Stage05。  
   - Stage07：依赖 Stage05、Stage06。  
   - Stage08：依赖 Stage07。

4. **结果位置**  
   - 缓存与中间结果：`results/cache/`  
   - 日志：`results/logs/`  
   - 图：`results/figs/`  
   - 表：`results/tables/`  

5. **多组航向批量（Stage06）**  
   若需多组航向配置批量跑，请直接调用 `stages/stage06_batch_heading_runs(cfg)`，并在 `params/default_params.m` 的 `cfg.stage06.batch` 中配置 `run_tags` 与 `heading_offset_sets`。

## 使用说明小结

1. 克隆仓库到本地。  
2. 在 MATLAB 中 `cd` 到工程根目录。  
3. 全流程：运行 `run_stages/run_all_stages`；或按需运行 `run_stages/run_stageXX_*`。  
4. 各 Stage 的步骤说明见 `run_stages/run_stageXX_*.m` 注释。

## 许可证与致谢

（按需填写。）
