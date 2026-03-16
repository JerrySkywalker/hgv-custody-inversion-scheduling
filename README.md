# CPT4 Disk Fresh

博士论文第四章仿真实验 MATLAB 工程。仓库现在支持两条并行工作流：

- `stages/` + `run_stages/`：功能开发顺序、调试、CI/CD 递进
- `milestones/` + `run_milestones/`：论文 Chapter 4 实验分组、复现实验与打包

## 环境要求

- MATLAB R2016b 或更高版本
- 建议 MATLAB R2020a 及以上
- 如需运行并行版本，建议安装 Parallel Computing Toolbox

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
├── benchmarks/
├── results/
│   ├── cache/
│   ├── figs/
│   ├── logs/
│   ├── tables/
│   ├── benchmarks/
│   └── bundles/
└── output/
    └── milestones/
        ├── milestone_summary_report.md
        ├── MA/
        ├── MB/
        ├── MC/
        ├── MD/
        └── ME/
```

## Stage vs Milestone

- `Stage` = 开发顺序。关注模块演化、调试、性能验证和阶段缓存。
- `Milestone` = 论文实验顺序。关注 Chapter 4 实验分组、稳定命名、统一导出与打包。
- Milestone 可以复用 Stage 函数，但 milestone 面向用户的产物不应暴露 stage 名称。

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

## Output Locations

Stage 输出仍放在 `results/`：

- `results/cache/`
- `results/figs/`
- `results/logs/`
- `results/tables/`
- `results/bundles/`

Milestone 输出放在 `output/milestones/`：

- `output/milestones/MA/cache/`
- `output/milestones/MA/figures/`
- `output/milestones/MA/tables/`
- `output/milestones/MA/reports/`
- `output/milestones/MB/...`
- `output/milestones/MC/...`
- `output/milestones/MD/...`
- `output/milestones/ME/...`

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
- 时序连续性现统一采用双指标：
  `DT_bar = dt_req / (dt_req + dt_max)` 用于有界展示与统计，
  `DT = 2 * DT_bar` 用于与 `DG/DA` 一致的 threshold-1 闭合判定。

## License

本项目采用 [MIT License](LICENSE)。
