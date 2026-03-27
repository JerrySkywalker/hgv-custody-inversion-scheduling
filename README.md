# CPT4 Disk Fresh

面向博士论文“高超声速滑翔飞行器连续托管任务下的感知需求反演与资源调度研究”的 MATLAB 仿真工程。

本仓库当前的主用途不是“通用航天仿真平台”，而是围绕论文第四章建立一套**可复算、可打包、可导出论文图表**的实验流水线，并为第五章预留共享场景、局部参考、最坏窗口诊断与邻域搜索等接口。工程主体采用三层组织：

1. **`src/`：算法与公共能力层**  
   放置轨迹、几何、可见性、窗口信息矩阵、Walker 搜索、FFT 结构化谱分析、诊断分析、日志与输出管理等底层函数。
2. **`stages/` + `run_stages/`：开发型分阶段流水线**  
   按“场景生成 → 轨迹传播 → 可见性 → 最坏窗口 → 静态搜索 → 诊断增强”的顺序组织，适合调试、逐步复算和方法开发。
3. **`milestones/` + `run_milestones/` + `shared_scenarios/`：论文导出层**  
   将 Stage 侧结果整理为论文第四章的 MA–ME 实验分组与 SS1–SS2 共享说明图，输出稳定命名的图、表、报告和 MAT 摘要。

---

## 1. 仓库定位

### 1.1 面向论文的定位

从当前代码和你上传的论文章节内容对照来看，本仓库与论文各章的关系如下：

- **第二章（托管定义、轨迹管道、状态机、双环框架）**  
  主要提供理论背景和指标语义来源。仓库中**没有完整实现第二章的“连续托管状态机/双环调度闭环”**，但若干指标与设计思想在第四章代码中被静态化、窗口化使用。
- **第三章（李导数-FIM 供给建模）**  
  仓库中通过 `stage03`、`stage04` 及 `src/sensing/`、`src/window/` 的信息矩阵构造、窗口聚合和谱量计算，给出了**面向第四章静态反演的供给侧数值实现**。
- **第四章（单层静态星座反演基准与最坏窗口机理）**  
  这是本仓库当前最完整、最成熟的主体。`stage01`–`stage11`、`stage12A`–`stage12F`、`milestones/MA`–`ME` 基本都服务于这一章。
- **第五章（动态资源调度）**  
  当前仓库只具备**前置支撑件和接口层**，例如共享说明图、局部参考/弱对称诊断、Stage13 邻域搜索等；**尚不是一套完整的第五章动态调度仿真系统**。

### 1.2 当前工程目标

当前工程主要完成以下任务：

- 构建防区—入界—目标轨迹—Walker 星座的统一实验场景；
- 计算可见性与窗口化信息矩阵；
- 识别最坏窗口并提取窗口级性能指标；
- 在单层 Walker 参数网格上进行静态反演搜索；
- 给出可行域、最小布置、参数切片和窗口尺度效应；
- 为结构化参考基准、FFT 快速谱分析和最坏窗口诊断提供计算支撑；
- 将开发结果整理为论文第四章所需的正式图表和 Markdown 摘要。

---

## 2. 当前代码仓库的总体功能概述

当前快照中，仓库共有约 **329 个 `.m` 文件**，其中包括：

- `src/`：204 个
- `stages/`：52 个
- `run_stages/`：24 个
- `milestones/`：15 个
- `run_milestones/`：7 个
- `shared_scenarios/`：4 个
- `run_shared_scenarios/`：3 个
- `benchmarks/`：11 个

从功能上看，整个仓库可以视为一个**以第四章为核心的论文实验工厂**，包含以下几类能力：

1. **基础配置与输出管理**  
   `startup.m`、`default_params.m`、日志系统、输出目录路由、快照打包。
2. **场景与目标建模**  
   防区圆盘、入界点集、名义/扩展/临界目标族，高超声速滑翔飞行器轨迹传播。
3. **星座与几何建模**  
   单层 Walker 星座构建、卫星传播、ECI/ECEF/ENU 坐标转换、可见性计算。
4. **窗口化观测供给建模**  
   窗口信息矩阵、最坏窗口扫描、门槛校准、谱量与裕度统计。
5. **静态反演与设计域搜索**  
   针对 `(h, i, P, T, F)` 网格扫描，计算 `D_G`、`D_A`、`D_T` 及综合约束。
6. **结构化参考与 FFT 快速分析**  
   Plane-cyclic / block-circulant 近似、FFT 模态、对称性破缺诊断。
7. **论文资产导出**  
   MA–ME 里程碑、SS1–SS2 共享场景说明图、Stage13 邻域搜索导出。
8. **基准测试与打包**  
   benchmark 运行、工程快照打包、清理输出目录。

---

## 3. 工程结构

```text
cpt4_sim_dev/
├── README.md
├── LICENSE
├── startup.m
├── params/
│   └── default_params.m
├── src/
│   ├── analysis/
│   ├── benchmark/
│   ├── common/
│   ├── constellation/
│   ├── fft/
│   ├── geo/
│   ├── scenario/
│   ├── search/
│   ├── sensing/
│   ├── stages/
│   │   └── stage13/
│   ├── target/
│   └── window/
├── stages/
├── run_stages/
├── milestones/
├── run_milestones/
├── shared_scenarios/
├── run_shared_scenarios/
├── benchmarks/
├── tests/
└── tools/
````

---

## 4. 与博士论文的功能映射

## 4.1 第二章对应关系

第二章的核心是“轨迹管道—托管定义—状态机—双环闭环”。当前代码并未完整实现这些抽象层，但以下内容是第二章在数值侧的落点：

* **“窗口化最坏情形”思想**：`stage04`、`stage08`、`stage09`
* **面向托管的三指标闭合思想**：`stage09` 的 `D_G / D_A / D_T`
* **最坏窗口触发与诊断解释**：`stage04`、`stage11`
* **为第五章局部参考/调度提供接口**：`stage11`、`stage13`

因此，这个仓库不是第二章理论的直接代码化，而是把第二章中最可操作的部分转化为第四章/第五章可用的计算接口。

## 4.2 第三章对应关系

第三章核心是“观测供给建模”。在当前仓库中的主要实现为：

* `src/sensing/compute_visibility_matrix_stage03.m`
  构造观测可见性
* `src/window/build_time_info_series_stage04.m`
  建立时间序列信息量
* `src/window/build_window_info_matrix_stage04.m`
  构造窗口信息矩阵
* `src/window/scan_worst_window_stage04.m`
  识别最坏窗口
* `src/window/calibrate_gamma_req_stage04.m`
  校准窗口门槛
* `src/window/compute_projected_accuracy_stage09.m`
  任务投影精度指标

也就是说，第三章的 FIM / 供给建模思想，已经在第四章静态搜索中转化为实际可算的窗口指标。

## 4.3 第四章对应关系

第四章是本仓库的主战场。对应关系大致为：

* **4.2 单层静态反演问题表述与窗口化设计尺度**
  `stage01`–`stage04`
* **4.3 单层静态反演真值基准与参数切片**
  `stage05`–`stage09`，以及 `MA`、`MB`
* **4.4 窗口尺度效应与三指标静态闭合**
  `stage08`、`MC`
* **4.5 结构化参考基准、快速谱计算支撑与诊断增强**
  `stage10`、`stage11`、`MD`、`ME`

## 4.4 第五章对应关系

第五章当前并未完整落地，但仓库中已有以下支撑件：

* `shared_scenarios/SS1`：二维防区说明图
* `shared_scenarios/SS2`：地球—Walker—防区三维说明图
* `stage11`：弱对称/子空间/诊断增强
* `stage13`：围绕基准工况的邻域参数搜索和代表案例整理

这些内容更适合作为第五章的**场景资产、局部参考、候选库与机理说明基础**，而不是第五章本身的完整实现。

---

## 5. Stage 系列功能总览

以下内容是基于当前代码仓库对 `Stage` 系列的逐项梳理。

## 5.1 Stage00–Stage04：从场景到最坏窗口

### Stage00 — `stage00_bootstrap`

功能：

* 验证 `startup`
* 初始化输出目录
* 加载默认配置
* 建立日志
* 验证 MAT 保存链路

定位：

* 工程启动自检
* 不直接对应论文某一节，但为所有后续阶段提供环境验证

### Stage01 — `stage01_scenario_disk`

功能：

* 构建抽象防区圆盘与入界边界
* 生成 casebank
* 支持地理锚点、ENU/ECEF/ECI 信息补充
* 输出名义、扩展、临界场景对象

定位：

* 第四章实验对象与场景设置的第一步
* 对应第四章“实验对象与场景设置”的底层实现

### Stage02 — `stage02_hgv_nominal`

功能：

* 使用 VTC HGV 动力学传播目标轨迹
* 生成轨迹族 `trajbank`
* 输出 ENU / ECEF / ECI 坐标
* 保持对 Stage01 casebank 的自然继承

定位：

* 将 Stage01 的几何 case 变为真正的目标轨迹
* 对应第四章实验中的目标动力学建模与轨迹生成

### Stage03 — `stage03_visibility_pipeline`

功能：

* 构建单层 Walker 基准星座
* 传播卫星状态
* 计算目标与星座的可见性矩阵
* 形成从轨迹到观测供给的第一层数值链路

定位：

* 第三章供给建模到第四章静态反演之间的桥梁
* 对应“观测几何与可见性建模”

### Stage04 — `stage04_window_worstcase`

功能：

* 构建窗口信息矩阵
* 计算窗口级谱量
* 扫描最坏窗口
* 校准 `gamma_req`
* 输出谱级和裕度级统计

定位：

* 第四章最关键的基准阶段之一
* 将“最坏窗口”从概念变为可算对象
* 是后续 Stage05–Stage11 的共同前置

---

## 5.2 Stage05–Stage09：静态搜索、切片与可行域

### Stage05 — 名义目标族下的 Walker 搜索

主要文件：

* `stage05_nominal_walker_search.m`
* `stage05_plot_nominal_results.m`
* `stage05_analyze_pareto_transition.m`

功能：

* 对名义目标族进行单层 Walker 参数扫描
* 搜索 `(i, P, T)` 或更广义设计参数的可行组合
* 形成可行解、前沿和过渡诊断
* 输出名义工况下的最小规模与性能变化

定位：

* 第四章“真值基准扫描”的初始版
* 更偏向开发型搜索与结构摸底

### Stage06 — 航向扩展目标族搜索

主要文件：

* `stage06_heading_walker_search.m`
* `stage06_compare_with_stage05.m`
* `stage06_batch_heading_runs.m`

功能：

* 在名义基础上加入 heading 扰动
* 构建扩展目标族
* 比较扩展族与名义族在所需星座规模上的差异
* 分析“V 字”或非单调现象的来源

定位：

* 第四章参数切片的重要来源之一
* 对应“扩展场景/扩展目标族”的静态搜索

### Stage07 — 临界几何与代表案例选择

主要文件：

* `stage07_select_reference_walker.m`
* `stage07_select_critical_examples.m`
* `stage07_scan_heading_risk_map.m`
* `stage07_plot_critical_geometry.m`

功能：

* 从前面搜索结果中挑选代表性 Walker 基准
* 识别临界案例和高风险几何
* 为论文正式出图准备代表工况

定位：

* 开发流水线中的“案例提纯层”
* 为 Stage08–Stage09 和 MA/MB 提供案例基础

### Stage08 — 窗口长度选择与窗口尺度效应

主要文件：

* `stage08_scan_representative_cases.m`
* `stage08_scan_smallgrid_search.m`
* `stage08_boundary_window_sensitivity.m`
* `stage08_finalize_window_selection.m`

功能：

* 比较不同 `T_w` 的影响
* 观察可行域、边界和最坏窗口位置的变化
* 给出推荐窗口长度
* 形成窗口尺度效应的正式总结

定位：

* 对应第四章“窗口尺度效应与三指标静态闭合”
* 是 `MC` 里程碑的重要底层来源

### Stage09 — 静态反演正式扫描

主要文件：

* `stage09_prepare_task_spec.m`
* `stage09_validate_single_design.m`
* `stage09_build_feasible_domain.m`
* `stage09_extract_minimum_boundary.m`
* `stage09_plot_inverse_design_results.m`

功能：

* 将单层 Walker 静态设计问题正式写成参数网格搜索
* 计算每个设计点的 `DG_rob / DA_rob / DT_bar_rob / DT_rob`
* 判定可行与否
* 提取最小布置边界与近优解
* 输出论文导向的可行域图、最小边界图、参数域表

定位：

* 第四章最核心的反演主阶段
* 真正将“需求 → 设计域 → 最小布置”数值化

说明：

* 当前 `Stage09` 已是论文第四章最重要的“真值扫描主核”之一。

---

## 5.3 Stage10–Stage11：结构化参考、FFT 与诊断增强

### Stage10 — 结构化参考基准与 FFT 支撑

子阶段包括：

* `stage10A_truth_structure_diagnostics`
* `stage10B_build_bcirc_reference`
* `stage10B1_legalize_bcirc_reference`
* `stage10C_fft_spectral_validation`
* `stage10D_symmetry_breaking_margin`
* `stage10E_screening_acceleration`
* `stage10E1_screening_refine_rule`
* `stage10F_finalize_report_pack`

功能：

* 从真值窗口矩阵中提取 plane-cyclic / block-circulant 结构参考
* 验证 FFT 模态与全矩阵谱的关系
* 定义对称性破缺误差/裕度
* 研究筛选规则与加速策略
* 输出汇总图表

定位：

* 对应第四章“结构化参考基准、快速谱计算支撑”
* 偏“支撑性、解释性、加速性”而非直接取代真值标准

重要说明：

* `Stage10` 的思想是：**真值仍以完整窗口矩阵为准，FFT/结构化结果主要作为参考、加速或诊断工具。**
* 当前仓库中的 `MD` 里程碑已经调用了 `Stage10C`，但其里程碑封装层仍保留了较多“包装型/展示型”内容，因此应视为**论文导出层已建，但完全工程化 benchmark 仍可继续增强**。

### Stage11 — 最坏窗口诊断增强

功能：

* 从 Stage10 的窗口级结果出发
* 建立弱对称分解、子空间下界和诊断表
* 生成窗口级与案例级诊断输出
* 为“为什么这个窗口最坏”提供解释性证据

定位：

* 对应第四章“最坏窗口诊断增强”
* 更偏解释性增强，而不是替换真值扫描

重要说明：

* `Stage11` 已具备真实计算骨架；
* 但 `ME` 里程碑封装目前仍包含一定的默认占位数据和容错逻辑，因此 README 中不宜把它描述成“完全成熟的论文终版主结果替代品”。

---

## 5.4 Stage12–Stage13：论文打包层与邻域扩展

### Stage12A–Stage12F

功能：

* 将 Stage09/Stage11 等开发结果重新封装成论文导向资产
* `12A`：真值基准核
* `12B`：单案例窗口扫描
* `12C`：参数切片打包
* `12D`：任务侧切片打包
* `12E`：最小设计结果打包
* `12F`：MB 调试验证

定位：

* 它们是 Milestone 层的直接底座
* 本质上属于“Stage 与 Milestone 之间的中间包装层”

### Stage13

位置：

* `src/stages/stage13/`
* 入口：`run_stages/run_stage13.m`

功能：

* 围绕基准案例进行邻域候选搜索
* 支持 DG-first / DT-first 等不同候选族
* 排序代表案例
* 输出可用于论文扩展说明的案例池

定位：

* 更像“第四章尾部 / 第五章前置”的辅助层
* 当前适合用来生成**基准邻域、对照案例、备用案例池**

---

## 6. Milestone 系列功能总览

Milestone 不是简单复制 Stage，而是把 Stage 的结果整理成论文第四章正式实验分组。

| Milestone | 含义                     | 对应论文角色           |
| --------- | ---------------------- | ---------------- |
| `MA`      | truth baseline         | 真值基准案例与最坏窗口主证据   |
| `MB`      | inverse slices         | 参数切片、任务切片与最小设计汇总 |
| `MC`      | window scale           | 窗口尺度效应与三指标闭合     |
| `MD`      | fft support            | FFT/结构化谱的计算支撑    |
| `ME`      | worst-window diagnosis | 最坏窗口诊断增强         |

## 6.1 MA — `milestone_A_truth_baseline`

功能：

* 固定论文主基准工况
* 导出真值最坏窗口曲线和总结表
* 作为第四章正文主案例

来源：

* `stage12A` + `stage12B`

## 6.2 MB — `milestone_B_inverse_slices`

功能：

* 汇总参数切片与任务切片
* 生成可行域表、最小设计表、近优解表
* 是第四章反演结果的正式资产封装

来源：

* `stage12C` + `stage12D` + `stage12E`

## 6.3 MC — `milestone_C_window_scale`

功能：

* 对多个窗口长度进行扫描和比较
* 输出 `DG / DA / DT_bar / DT` 随 `Tw` 的变化
* 给出窗口推荐与闭合结论

来源：

* `stage08` 系列

## 6.4 MD — `milestone_D_fft_support`

功能：

* 以论文导出视角汇总 FFT 支撑
* 给出“直接计算 vs FFT 支撑”的复杂度图表

来源：

* 调用 `stage10C`，并附加报告层封装

重要说明：

* 当前 `MD` 已可用于论文中“计算支撑/复杂度说明”的位置；
* 但它不是一个严格意义上全链路 runtime benchmark 平台。

## 6.5 ME — `milestone_E_worst_window_diagnosis`

功能：

* 对 Stage11 的诊断结果进行论文打包
* 输出代表性诊断图表和汇总报告

来源：

* 调用 `stage11_entry`

重要说明：

* 当前 `ME` 已具备诊断导出用途；
* 但其封装中仍保留占位默认值和异常容错分支，因此更适合表述为**诊断增强层**，不宜表述为“完全替代真值的正式判据层”。

---

## 7. Shared Scenarios 的作用

共享场景不是开发流水线的一部分，而是**第四章与第五章共用的说明资产**。

## 7.1 SS1 — 二维防区说明图

文件：

* `shared_scenario_SS1_defense_zone_2d.m`

功能：

* 绘制二维防区、入界点、代表轨迹的关系图
* 为正文中的场景说明提供统一图源

后端来源：

* `stage01` + 共享轨迹构造函数

## 7.2 SS2 — 地球 / Walker / 防区三维说明图

文件：

* `shared_scenario_SS2_earth_walker_zone_3d.m`

功能：

* 绘制地球、Walker 星座与防区的空间关系
* 优先使用 STK-MATLAB 接口
* 若 STK 状态导出失败，则回退到本地传播

作用：

* 为第四章和第五章共用空间关系说明图

---

## 8. `src/` 各模块功能说明

## 8.1 `src/common/`

工程公共能力层，包括：

* 日志初始化与打印
* 输出目录配置
* 随机种子
* 并行池管理
* 缓存查找与安全保存
* Stage09/10/11 的配置预处理

这是整个工程的基础设施层。

## 8.2 `src/geo/`

坐标与时间变换层，包括：

* Geodetic / ECEF / ECI / ENU 变换
* Julian Date / GMST
* 局部坐标基构造

用于目标、卫星、场景之间的坐标统一。

## 8.3 `src/scenario/`

场景构造层，包括：

* 防区圆盘
* 入界边界
* 名义目标族
* 航向扰动目标族
* 临界族生成
* Stage01 的 casebank 绘图与摘要

## 8.4 `src/target/`

目标动力学层，包括：

* HGV 动力学
* 控制剖面
* 轨迹传播
* 事件终止函数
* 轨迹摘要与可视化

这是 Stage02 的主要底层。

## 8.5 `src/constellation/`

星座构建与传播层，包括：

* 单层 Walker 构建
* 星座传播

对应 Stage03 及后续搜索阶段的卫星状态生成。

## 8.6 `src/sensing/`

观测几何层，包括：

* LOS 几何
* 可见性判定
* 目标惯性坐标对接
* 可见性案例摘要

对应第三章供给建模在本工程中的数值入口。

## 8.7 `src/window/`

窗口信息矩阵与指标层，包括：

* 时间信息序列构建
* 窗口网格构建
* 窗口信息矩阵构造
* 最坏窗口扫描
* 裕度计算
* Stage09 所需投影精度和窗口指标

这是本仓库最关键的数值主核之一。

## 8.8 `src/search/`

静态搜索层，包括：

* Stage05、Stage06、Stage09 的搜索网格构造
* 单层 Walker 评估器
* 可行域提取和边界提取
* 搜索结果摘要

这是静态反演的直接实现层。

## 8.9 `src/fft/`

结构化参考与 FFT 层，包括：

* 平面分块张量构造
* block-circulant 原型构造
* FFT 模态分解
* 全矩阵 vs FFT 结果比较
* 对称性破缺度量

对应第四章后半部分的加速和机理解释支撑。

## 8.10 `src/analysis/`

论文图表与分析包装层，包括：

* 论文风格绘图
* Stage09/10/11 汇总表构造
* shared scenario 几何生成
* MB/Stage10/Stage11 论文图生成
* STK 可用性检查与状态导出

这个目录本质上是“开发结果 → 论文资产”的中间分析层。

## 8.11 `src/stages/stage13/`

Stage13 的专用实现层，包括：

* 邻域搜索计划
* 候选案例评估
* 排序与导出
* 论文备用案例整理

---

## 9. 输出目录规范

仓库当前统一使用 `outputs/` 作为输出根目录。

## 9.1 非跟踪开发产物

默认不纳入版本控制：

* `outputs/stage/`
* `outputs/benchmark/`
* `outputs/logs/`
* `outputs/bundles/`

其中：

* `outputs/stage/stage00`–`stage11`
  保存各 Stage 的 cache / figs / tables
* `outputs/logs/stageXX`
  保存日志
* `outputs/benchmark/`
  保存 benchmark 报告
* `outputs/bundles/`
  保存工程打包结果

## 9.2 论文正式资产

默认作为论文导出资产：

* `outputs/milestones/MA`
* `outputs/milestones/MB`
* `outputs/milestones/MC`
* `outputs/milestones/MD`
* `outputs/milestones/ME`
* `outputs/shared_scenarios/SS1`
* `outputs/shared_scenarios/SS2`
* `outputs/stage/stage13`

说明：

* Milestone 目录下通常包含 `data/`、`figures/`、`tables/`、`reports/`
* Shared scenario 目录下通常包含 `figures/`、`reports/`
* Stage13 目录下通常包含导出图表、候选表和汇总报告

---

## 10. 运行入口

## 10.1 初始化

```matlab
startup
```

如需强制刷新路径：

```matlab
startup('force', true)
```

## 10.2 运行单个 Stage

```matlab
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
run_stage11
run_stage13
```

## 10.3 运行完整开发流水线

```matlab
run_all_stages
```

也可以指定最终停止阶段，例如：

```matlab
run_all_stages(false, true, true, true, 9)
```

表示运行到 Stage09。

## 10.4 运行单个 Milestone

```matlab
run_milestone_A_truth_baseline
run_milestone_B_inverse_slices
run_milestone_C_window_scale
run_milestone_D_fft_support
run_milestone_E_worst_window_diagnosis
```

## 10.5 运行全部 Milestones

```matlab
run_all_milestones
```

## 10.6 运行共享场景说明图

```matlab
run_shared_scenario_SS1_defense_zone_2d
run_shared_scenario_SS2_earth_walker_zone_3d
run_all_shared_scenarios
```

## 10.7 运行基准测试

```matlab
run_benchmark_stage00
run_benchmark_stage04
run_benchmark_stage09
```

---

## 11. 配置入口

统一配置文件：

* `params/default_params.m`

其中包含：

* 基础路径和随机种子
* Stage01–Stage11 参数
* Walker 搜索域
* 窗口参数
* Stage09 反演阈值
* Stage10 FFT 结构化参数
* Stage11 诊断参数

说明：

* `default_params.m` 是整个工程的唯一总配置源；
* 各 Stage 在运行前通常还会调用对应的 `stageXX_prepare_cfg` 做二次整理；
* Milestone 和 Shared Scenario 也会在此基础上再覆盖自己的导出参数。

---

## 12. 当前成熟度判断

基于当前代码快照，建议按下面方式理解仓库成熟度：

### 12.1 已较成熟的部分

* `startup` / 输出目录 / 日志 / 打包链路
* Stage01–Stage04
* Stage05–Stage09 的第四章主搜索链路
* MA / MB / MC 的论文导出主链
* SS1 / SS2 的共享说明图框架

### 12.2 已有真实骨架但仍可继续加强的部分

* Stage10 的结构化参考、FFT 验证和筛选
* Stage11 的诊断增强
* Stage13 的邻域案例池构造

### 12.3 当前不应过度宣称为“已完整实现”的部分

* 第五章动态调度主算法与完整对比实验
* 以 FFT/结构化方法替代真值判据的完整闭环
* 以 Stage11/ME 作为论文唯一最终判据

---

## 13. 开发与论文写作建议

本仓库当前最合理的使用方式是：

1. **第四章正文主证据**
   以 `Stage04 + Stage08 + Stage09 + MA + MB + MC` 为主。
2. **第四章后半章支撑性内容**
   以 `Stage10 + Stage11 + MD + ME` 为计算支撑、诊断增强、机理说明。
3. **第五章前置资产**
   使用 `SS1 + SS2 + Stage13` 作为场景图和局部参考案例来源，但不要把它们误写成完整动态调度系统。
4. **开发时优先维护 Stage 真值链**
   论文主结论仍应建立在 Stage04/09 的真值窗口链路上，而不是建立在包装层或诊断层上。

---

## 14. 打包与清理工具

### 14.1 清理输出

* `tools/clean/clean_outputs.m`
* `tools/clean/clean_outputs.ps1`

### 14.2 打包快照

* `tools/pack/pack_project_snapshot_all.m`
* `tools/pack/pack_project_snapshot_all_code.m`
* `tools/pack/pack_project_snapshot_head.m`
* `tools/pack/pack_project_snapshot_head_code.m`

说明：

* 支持打包当前工作区或 HEAD
* 支持只打代码，或包含论文导出资产
* 包名会自动带上分支名

---

## 15. 环境要求

* MATLAB R2016b 或更高版本
* 建议 MATLAB R2020a 及以上
* 如需并行搜索，建议安装 Parallel Computing Toolbox
* 如需 `SS2` 的 STK 驱动三维场景，需安装 STK 并启用 MATLAB COM 接口

---

## 16. 许可证

本项目采用 [MIT License](LICENSE)。

---

## 17. 一句话总结

这不是一个泛化的“航天仿真框架”，而是一套围绕博士论文第四章构建、以**最坏窗口—三指标闭合—单层静态反演**为主线，并向第五章局部参考与诊断增强延伸的 MATLAB 论文实验工程。喵~

