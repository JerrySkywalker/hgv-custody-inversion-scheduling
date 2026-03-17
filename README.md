# CPT4 Disk Fresh

博士论文第四章仿真实验 MATLAB 工程。

仓库当前采用统一输出根目录 `outputs/`：

- `outputs/stage/`、`outputs/benchmark/`、`outputs/logs/`、`outputs/bundles/` 是本地开发产物，默认不纳入版本控制
- `outputs/milestones/`、`outputs/shared_scenarios/`、`outputs/stage13/` 是论文正式导出资产，默认纳入版本控制
- 旧的 `results/` 与 `output/` 目录不再作为推荐输出语义，仅视为 legacy 历史痕迹

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
└── outputs/
    ├── stage/
    ├── benchmark/
    ├── logs/
    ├── bundles/
    ├── milestones/
    │   ├── milestone_summary_report.md
    │   ├── MA/
    │   ├── MB/
    │   ├── MC/
    │   ├── MD/
    │   └── ME/
    ├── shared_scenarios/
    │   ├── SS1/
    │   └── SS2/
    └── stage13/
```

## Stage vs Milestone

- `stages/` + `run_stages/` 面向功能开发顺序、调试和复算
- `milestones/` + `run_milestones/` 面向论文 Chapter 4 实验分组、稳定命名和正式导出
- `shared_scenarios/` + `run_shared_scenarios/` 面向第四章与第五章共用说明图
- `stage13` 面向扩展搜索与 dissertation-facing 导出

Milestone、shared scenario 与 Stage13 的正式资产统一写入 `outputs/` 下的论文资产目录；Stage 与 benchmark 的运行缓存统一写入 `outputs/` 下的非跟踪目录。

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

运行 Stage13：

```matlab
run_stage13
```

## Output Locations

本地开发产物：

- `outputs/stage/stage00` 到 `outputs/stage/stage11` 分别保存对应 Stage 的缓存、图、表和中间 MAT 结果
- `outputs/benchmark/` 保存 benchmark 报告
- `outputs/logs/stage00` 到 `outputs/logs/stage11` 保存对应 Stage 的运行日志
- `outputs/bundles/` 保存打包文件或快照

论文正式导出资产：

- `outputs/milestones/MA/data|figures|tables|reports`
- `outputs/milestones/MB/data|figures|tables|reports`
- `outputs/milestones/MC/data|figures|tables|reports`
- `outputs/milestones/MD/data|figures|tables|reports`
- `outputs/milestones/ME/data|figures|tables|reports`
- `outputs/shared_scenarios/SS1/data|figures|reports`
- `outputs/shared_scenarios/SS2/data|figures|reports`
- `outputs/stage13/data|figures|tables|reports`

说明：

- 这里的 `data/` 是论文资产快照，不再使用 `cache/` 命名
- `run_all_milestones` 汇总报告写入 `outputs/milestones/milestone_summary_report.md`
- `run_all_shared_scenarios` 产物写入 `outputs/shared_scenarios/SS1` 与 `outputs/shared_scenarios/SS2`
- `run_stage13` 产物写入 `outputs/stage13`

## Git Tracking Rules

默认忽略：

- `outputs/stage/**`
- `outputs/benchmark/**`
- `outputs/logs/**`
- `outputs/bundles/**`

默认跟踪：

- `outputs/milestones/**`
- `outputs/shared_scenarios/**`
- `outputs/stage13/**`

## Packaging

根目录 pack 脚本已切换到 `outputs/` 语义：

- `package_for_chatgpt()` 会打包当前工作区代码目录，以及轻量 paper markdown 报告
- `package_for_chatgpt(true)` 可显式包含 `outputs/milestones|shared_scenarios|stage13`
- `package_for_chatgpt_baseline(false, true)` 可从 `HEAD` 打包已跟踪的 `outputs/` 论文资产
- 包名现在会自动包含当前 branch，例如 `20260317_153000_dev_working.zip`
- 底层实现文件分别是 `pack_snapshot_all.m` 与 `pack_snapshot_head.m`，同时保留 `package_for_chatgpt*` 兼容入口

## Notes

- `default_params.m` 中保留了少量旧字段兼容映射，例如 `cfg.paths.results` 与 `cfg.paths.output`，但它们现在都映射到新的 stage-scoped `outputs/` 结构
- Stage 侧仍可继续使用 `cfg.paths.cache/logs/figs/tables`，但这些字段现在会自动解析到当前 `stageXX` 专属目录
- 跨 Stage 读取旧缓存时，代码通过公共 helper 在 `outputs/stage/stageXX/cache` 间查找，不再依赖共享 `results/cache`
- `run_stages/rs_apply_parallel_policy.m` 仍是 Stage 默认并行策略的控制点
- `SS2` 当前采用 STK-MATLAB 接口建场景；若 STK 状态报表导出失败，代码会保留 STK 侧接口并以同参数本地传播完成出图

## License

本项目采用 [MIT License](LICENSE)。
