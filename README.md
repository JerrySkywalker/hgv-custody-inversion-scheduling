# CPT4 Disk Fresh

博士论文第四章仿真实验 MATLAB 工程。项目采用按 `Stage` 推进、按 benchmark 驱动优化的开发方式：先建立可重复测速与结果一致性校验，再围绕热点阶段逐步做串并行重构。

当前工程已经形成两条主线：

- `stages/` 与 `run_stages/`：负责正式实验流程
- `benchmarks/`：负责固定输入、串并行对照、speedup 统计与回归校验

## 环境要求

- MATLAB R2016b 或更高版本
- 建议 MATLAB R2020a 及以上
- 如需运行并行版本，建议安装 Parallel Computing Toolbox

## 工程结构

```text
cpt4_sim_dev/
├── README.md
├── startup.m
├── params/
│   └── default_params.m
├── benchmarks/
│   ├── run_benchmark_stage00.m
│   ├── run_benchmark_stage01.m
│   ├── run_benchmark_stage02.m
│   ├── run_benchmark_stage03.m
│   ├── run_benchmark_stage04.m
│   ├── run_benchmark_stage05.m
│   ├── run_benchmark_stage06.m
│   ├── run_benchmark_stage07.m
│   ├── run_benchmark_stage08.m
│   ├── run_benchmark_stage08c.m
│   └── run_benchmark_stage09.m
├── stages/
│   ├── stage00_bootstrap.m
│   ├── stage01_scenario_disk.m
│   ├── stage02_hgv_nominal.m
│   ├── stage03_visibility_pipeline.m
│   ├── stage04_window_worstcase.m
│   ├── stage05_nominal_walker_search.m
│   ├── stage06_heading_walker_search.m
│   ├── stage07_scan_heading_risk_map.m
│   ├── stage08_scan_smallgrid_search.m
│   ├── stage08_boundary_window_sensitivity.m
│   ├── stage09_build_feasible_domain.m
│   ├── stage09_extract_minimum_boundary.m
│   ├── stage10A_truth_structure_diagnostics.m
│   ├── stage10B_build_bcirc_reference.m
│   ├── stage10C_fft_spectral_validation.m
│   ├── stage10D_symmetry_breaking_margin.m
│   ├── stage10E_screening_acceleration.m
│   └── stage10F_finalize_report_pack.m
├── run_stages/
│   ├── run_stage00_bootstrap.m
│   ├── run_stage01_scenario_disk.m
│   ├── run_stage02_hgv_nominal.m
│   ├── run_stage03_visibility_pipeline.m
│   ├── run_stage04_window_worstcase.m
│   ├── run_stage05_nominal_walker.m
│   ├── run_stage06_heading_walker.m
│   ├── run_stage07_critical_geometry.m
│   ├── run_stage08_window_selection.m
│   ├── run_stage09_inverse_scan.m
│   ├── run_stage09_inverse_plot.m
│   ├── run_stage10.m
│   ├── run_all_stages.m
│   └── rs_apply_parallel_policy.m
├── src/
├── results/
│   ├── benchmarks/
│   ├── cache/
│   ├── figs/
│   ├── logs/
│   ├── tables/
│   └── bundles/
└── deliverables/
```

## Stage 概览

| Stage | 含义 | 主要输出 |
|---|---|---|
| `Stage00` | 工程引导、目录与环境自检 | 路径初始化、日志目录、cache 目录、默认配置 |
| `Stage01` | 保护盘场景与案例库构建 | `casebank`、场景图、代表性案例 |
| `Stage02` | HGV 标称轨迹传播 | `trajbank`、轨迹几何统计、传播缓存 |
| `Stage03` | 可见性计算管线 | `satbank`、`visbank`、可见性矩阵与 LOS 几何 |
| `Stage04` | 时间窗最坏情况分析 | `winbank`、信息矩阵、`gamma_req` 与 margin 统计 |
| `Stage05` | 标称族 Walker 搜索 | 搜索缓存、可行域表、Pareto 与倾角前沿 |
| `Stage06` | 航向族 Walker 搜索 | 航向搜索结果、与 Stage05 对比、结果图 |
| `Stage07` | 临界几何扫描与论文图 | 参考 Walker、风险图、关键案例与论文图 |
| `Stage08` | 窗长扫描与窗口选型 | 小网格扫描、统计表、最终推荐窗口 |
| `Stage08c` | 边界窗口敏感度分析 | hard-case 边界扫描、敏感度统计 |
| `Stage09` | 逆向设计与可行域提取 | feasible domain、minimum boundary、单点验证 |
| `Stage10` | 频谱/对称性/加速筛选等最终验证 | 结构诊断、FFT 验证、margin 校核、报告打包 |

## 快速开始

1. 在 MATLAB 中切换到工程根目录

2. 初始化工程路径

```matlab
startup
```

3. 按需选择运行方式

- 运行全流程

```matlab
run_all_stages()
```

- 只运行某个阶段

```matlab
run_stage00_bootstrap
run_stage01_scenario_disk
run_stage02_hgv_nominal
run_stage03_visibility_pipeline
run_stage04_window_worstcase
run_stage05_nominal_walker
run_stage06_heading_walker
run_stage07_critical_geometry
run_stage08_window_selection
run_stage09_inverse_scan
run_stage09_inverse_plot
run_stage10
```

## `run_all_stages()` 说明

`run_all_stages()` 是当前推荐的一键入口。

当用户直接运行：

```matlab
run_all_stages()
```

程序会先弹出一个问题，请用户选择“运行到哪个最终 Stage”，取值范围为 `1` 到 `10`，默认值为 `10`。

运行逻辑为：

- 始终先运行 `Stage00`
- 然后从 `Stage01` 依次运行到用户选择的最终 Stage
- 若最终 Stage 小于 `9`，则不会进入 `Stage09`
- 若最终 Stage 小于 `10`，则不会进入 `Stage10`

这使得同一个入口既可以用于全流程实验，也可以用于只跑到中间某个阶段的回归检查。

## Stage 依赖关系

- `Stage00`：无依赖，建议始终最先运行
- `Stage01`：建议在 `Stage00` 之后运行
- `Stage02`：依赖 `Stage01`
- `Stage03`：依赖 `Stage02`
- `Stage04`：依赖 `Stage03`
- `Stage05`：依赖 `Stage04`
- `Stage06`：依赖 `Stage05`
- `Stage07`：依赖 `Stage05` 与 `Stage06`
- `Stage08` / `Stage08c`：依赖 `Stage07`
- `Stage09`：依赖 `Stage08`
- `Stage10`：依赖 `Stage09`

严格来说，很多 Stage 依赖的是前序缓存而不是脚本本身；因此如果缓存已经存在，也可以单独重跑某个阶段。

## 统一接口与并行策略

为了支持 benchmark 与逐 Stage 并行化重构，核心阶段已经逐步统一到如下接口风格：

```matlab
result = solver(input, opts)
```

其中：

- `input`：固定测试输入或阶段输入
- `opts.mode`：`'serial'` 或 `'parallel'`
- `opts.parallel_config`：并行参数
- `result`：统一结果结构体

项目里“默认某个 Stage 该串行还是并行”的控制点不在 `default_params.m`，而在：

- `run_stages/rs_apply_parallel_policy.m`

这层负责流程级策略。  
`default_params.m` 则负责“如果并行，要用什么技术参数”，例如 pool profile、worker 数、自动启池等。

当前默认模式如下：

| Stage | 默认模式 | 说明 |
|---|---|---|
| `Stage01` | `serial` | 任务粒度较小，不适合作为主要并行优化目标 |
| `Stage02` | `serial` | 并行收益不稳定，ODE 内核仍是主要瓶颈 |
| `Stage03` | `parallel` | benchmark 已验证并行明显更快 |
| `Stage04` | `serial` | 并行仅略快，暂不切默认 |
| `Stage05` | `serial` | 稳态有收益，但 cold 口径仍不稳定 |
| `Stage06` | `serial` | 边界收益，先保守保持串行 |
| `Stage07` | `parallel` | benchmark 已验证并行更快 |
| `Stage08` | `parallel` | 小网格扫描在任务级并行上收益明显 |
| `Stage09` | `parallel` | 可行域扫描并行收益显著 |
| `Stage10` | `serial` | 一次性全流程场景下并行初始化成本过高 |

后续若某个 Stage 的并行优化效果已经被 benchmark 证明足够稳定，只需更新 `rs_apply_parallel_policy.m` 即可，不需要再逐个 wrapper 手改。

## Benchmark 框架

### 设计目标

benchmark 层用于支持“先测再改，再测再比”的开发节奏，避免并行化重构只凭感觉推进。

每个 benchmark 入口只负责四件事：

- 构造固定输入
- 分别运行串行版与并行版
- 记录耗时与 speedup
- 校验输出一致性

### 当前入口

当前已经提供以下 benchmark：

- `run_benchmark_stage00`
- `run_benchmark_stage01`
- `run_benchmark_stage02`
- `run_benchmark_stage03`
- `run_benchmark_stage04`
- `run_benchmark_stage05`
- `run_benchmark_stage06`
- `run_benchmark_stage07`
- `run_benchmark_stage08`
- `run_benchmark_stage08c`
- `run_benchmark_stage09`

例如：

```matlab
run_benchmark_stage03
run_benchmark_stage08
run_benchmark_stage09
```

### 报告内容

benchmark 结果会保存到 `results/benchmarks/`，通常包含：

- 串行与并行运行时间
- `speedup`
- 输入规模与并行参数
- Git commit hash
- MATLAB 版本
- 机器信息
- 输出一致性比较结果

### `cold` 与 `warm`

当前 benchmark 同时保留两种观察口径：

- `cold`：排除 `parpool` 创建时间，但保留首次真正执行并行内核时的冷启动成本
- `warm`：在不计时预热一次并行内核后，再测稳定态性能

对于本工程，推荐的主决策口径仍然是 `cold`，因为实际实验仿真往往更接近“一次性跑完整流程”；`warm` 更适合判断某个并行内核本身是否有潜力。

## 结果目录

- `results/cache/`：各 Stage 中间缓存
- `results/benchmarks/`：benchmark 报告与对照结果
- `results/logs/`：日志
- `results/figs/`：图形输出
- `results/tables/`：表格输出
- `results/bundles/`：打包结果

## 开发与维护约定

- 新的性能优化优先通过 benchmark 驱动，而不是直接改业务主流程
- 串行与并行尽量共享同一业务入口，只在 `opts.mode` 上分流
- benchmark 逻辑不要混入正式业务脚本
- 每个重要优化阶段尽量独立提交，便于回滚与回归比较
- 默认串并行策略以 `rs_apply_parallel_policy.m` 为准

## 备注

- `Stage10` 目前尚未纳入正式 benchmark 入口。现阶段判断是：在“一次性全流程运行”的真实场景下，`Stage10` 更适合保持串行默认。
- 各 `run_stageXX_*.m` 文件头部注释仍然是最细的阶段级说明来源；若需要了解单个 Stage 的详细执行顺序，建议直接查看对应 wrapper。

## 许可证与致谢

本项目采用 **MIT 许可证** 发布。详见 [LICENSE](LICENSE) 文件。

MIT 许可证允许你：
- ✓ 自由使用、修改与分发本项目
- ✓ 将本项目用于商业目的
- ✓ 将本项目用于私有项目

但需要：
- 在副本及衍生品中保留原始许可证与版权说明
