# CPT4 Disk Fresh

博士论文第四章仿真实验 MATLAB 工程。仓库现在支持两条并行工作流：

- `stages/` + `run_stages/`：功能开发顺序、调试、CI/CD 递进
- `milestones/` + `run_milestones/`：论文 Chapter 4 实验分组、复现实验与打包
- `shared_scenarios/` + `run_shared_scenarios/`：第四章与第五章共用的说明型场景图

仓库输出策略：

- `output/` 保存论文图、表、报告和 Stage13 对照实验产物，属于应跟踪目录
- `results/` 保存 Stage/benchmark 缓存、日志和临时图表，默认视为缓存，不纳入版本控制

## 环境要求

- MATLAB R2016b 或更高版本
- 建议 MATLAB R2020a 及以上
- 如需运行并行版本，建议安装 Parallel Computing Toolbox
- 如需运行 `shared_scenarios/SS2` 的 STK 驱动 Walker 星座说明图，需安装 STK 并启用 MATLAB COM 接口

## Project Structure

```text
cpt4_sim_dev/
├── README.md
├── startup.m
├── params/
├── src/
├── stages/
├── run_stages/
├── milestones/
├── run_milestones/
├── shared_scenarios/
├── run_shared_scenarios/
├── benchmarks/
├── results/
│   ├── cache/
│   ├── figs/
│   ├── logs/
│   ├── tables/
│   ├── benchmarks/
│   └── bundles/
└── output/
    ├── milestones/
    │   ├── milestone_summary_report.md
    │   ├── MA/
    │   ├── MB/
    │   ├── MC/
    │   ├── MD/
    │   └── ME/
    ├── stage13/
    └── shared_scenarios/
        ├── SS1/
        └── SS2/
```

## Stage vs Milestone

- `Stage` = 开发顺序。关注模块演化、调试、性能验证和阶段缓存。
- `Milestone` = 论文实验顺序。关注 Chapter 4 实验分组、稳定命名、统一导出与打包。
- `Shared scenario` = 论文跨章节说明图。关注防区、Walker 星座与目标来袭关系的共用示意，不承载单独实验结论。
- `output/` 下的 milestone/shared_scenarios/Stage13 图表报告是论文资产；`results/` 下的 `cache/logs/figs/tables` 主要服务于 Stage 调试与复算。
- Milestone 可以复用 Stage 函数，但 milestone 面向用户的产物不应暴露 stage 名称。
- 当前共享场景后端定义为：
  `SS1` 复用 Stage01/Stage02 的防区与 HGV 相对关系语义，
  `SS2` 通过 STK-MATLAB 接口生成 Walker 星座说明图，并预留后续 STK 侧轨道状态导出接口。

## Chapter 4 Milestone Mapping

| Milestone | Meaning |
|---|---|
| `MA` | truth baseline |
| `MB` | inverse slices |
| `MC` | window scale |
| `MD` | FFT support |
| `ME` | worst-window diagnosis |

主要入口：

- `milestones/milestone_A_truth_baseline.m`
- `milestones/milestone_B_inverse_slices.m`
- `milestones/milestone_C_window_scale.m`
- `milestones/milestone_D_fft_support.m`
- `milestones/milestone_E_worst_window_diagnosis.m`

## How To Run

先初始化路径：

```matlab
startup
```

运行单个 stage：

```matlab
run_stage04_window_worstcase
run_stage09_inverse_scan
run_stage10
```

运行单个 milestone：

```matlab
run_milestone_A_truth_baseline
run_milestone_B_inverse_slices
run_milestone_C_window_scale
run_milestone_D_fft_support
run_milestone_E_worst_window_diagnosis
```

运行全部 milestones：

```matlab
run_all_milestones
```

运行共享场景说明图：

```matlab
run_shared_scenario_SS1_defense_zone_2d
run_shared_scenario_SS2_earth_walker_zone_3d
run_all_shared_scenarios
```

其中：

- `SS1` 输出二维防区与 HGV 相对关系说明图，直接对应 Stage01/Stage02 的场景构型语义
- `SS2` 输出三维 Walker 星座示意图，优先通过 STK-MATLAB 建场景，并为未来 STK 轨道传播/状态导出预留接口

## Output Locations

Stage 输出仍放在 `results/`，这些目录默认作为缓存处理：

- `results/cache/`
- `results/figs/`
- `results/logs/`
- `results/tables/`
- `results/bundles/`

论文正式导出结果放在 `output/`，这些目录应保持版本可追踪：

- `output/milestones/MA/cache/`
- `output/milestones/MA/figures/`
- `output/milestones/MA/tables/`
- `output/milestones/MA/reports/`
- `output/milestones/MB/...`
- `output/milestones/MC/...`
- `output/milestones/MD/...`
- `output/milestones/ME/...`
- `output/stage13/figures/`
- `output/stage13/tables/`
- `output/stage13/reports/`
- `output/shared_scenarios/SS1/figures/`
- `output/shared_scenarios/SS1/reports/`
- `output/shared_scenarios/SS2/figures/`
- `output/shared_scenarios/SS2/reports/`

`run_all_milestones` 还会生成顶层汇总：

- `output/milestones/milestone_summary_report.md`

## Packaging

根目录 pack 脚本已同步支持 milestone 框架：

- 默认会打包 `milestones/` 与 `run_milestones/`
- 默认只包含轻量 milestone markdown 汇总
- 默认不包含重缓存、图像与表格目录
- 可通过 `include_milestone_outputs = true` 显式打包 milestone 输出
- 工作区快照命名格式为 `yyyymmdd_HHMMSS_working.zip`
- HEAD 基线快照命名格式为 `yyyymmdd_HHMMSS_head.zip`

示例：

```matlab
package_for_chatgpt()
package_for_chatgpt(true)
package_for_chatgpt_baseline(false, true)
```

## Notes

- Benchmark 体系仍然服务于 Stage 级串并行优化和结果一致性校验。
- `run_stages/rs_apply_parallel_policy.m` 仍是 Stage 默认并行策略的控制点。
- Milestone 当前优先提供论文实验骨架和统一产物格式，不替代 benchmark。
- Shared scenario 包与 milestone A–E 并行存在，用于生成第四章与第五章共用的说明型图件。
- `SS2` 当前采用 STK-MATLAB 接口建场景；若 STK 建场景成功但状态报表导出失败，代码会保留 STK 侧接口并以同参数本地传播完成出图，避免说明图流程中断。
- 时序连续性现统一采用双指标：
  `DT_bar = dt_req / (dt_req + dt_max)` 用于有界展示与统计，
  `DT = 2 * DT_bar` 用于与 `DG/DA` 一致的 threshold-1 闭合判定。

## License

本项目采用 [MIT License](LICENSE)。
