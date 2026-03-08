# Milestone M1：第四章基线实验包

## 1. 目标

本里程碑用于固化第四章前半部分的基线实验结果，覆盖以下阶段性工作：

- 场景与进入条件定义；
- 目标轨迹样本库构建；
- 单层 Walker 观测基线建立；
- 最坏窗口谱退化与门槛化判定。

本里程碑的目标不是继续开发算法，而是将已有结果整理为：

- 可复现的 milestone 导出物；
- 可追踪的图表与表格结果；
- 可直接迁移进入论文第四章的文字说明素材。

---

## 2. 图形导出约定

本里程碑中的图片由 `milestone_m1_export_baseline.m` 统一导出，并采用如下约定：

1. **默认不在图内显示标题**。  
   这样做的原因在于最终论文排版时，图题与图注通常由 LaTeX 或 Word 统一管理，而不是直接使用 MATLAB 的 `title`。

2. **图标题文本仍保留在脚本的用户选项区，可按需打开**。  
   当需要快速预览或单独汇报时，可将：
   ```matlab
   opt.show_titles = true;

打开，以便在图中显示说明性标题。

1. **图名中不包含阶段序号意义上的论文编号**。
   例如，图中不会写 “Stage04.2 ...” 作为正式论文图题，因为最终图序将由论文排版系统统一给定。

------

## 3. 输入来源

本里程碑默认读取各阶段的最新 cache：

- Stage01 cache: `results/cache/stage01_scenario_disk_*.mat`
- Stage02 cache: `results/cache/stage02_hgv_nominal_*.mat`
- Stage03 cache: `results/cache/stage03_visibility_pipeline_*.mat`
- Stage04 cache: `results/cache/stage04_window_worstcase_*.mat`

------

## 4. 导出目录

导出物输出到：

- `deliverables/milestone_m1/figs/`
- `deliverables/milestone_m1/tables/`
- `deliverables/milestone_m1/notes/`

------

## 5. M1.1：场景与轨迹基线

### 5.1 图片

![场景设计图](https://chatgpt.com/deliverables/milestone_m1/figs/fig_m1_1_scenario.png)

![区域平面内的代表性轨迹](https://chatgpt.com/deliverables/milestone_m1/figs/fig_m1_1_traj_2d.png)

![代表性三维轨迹](https://chatgpt.com/deliverables/milestone_m1/figs/fig_m1_1_traj_3d.png)

### 5.2 表格

- `tab_m1_1_case_design.csv`
- `tab_m1_1_traj_family_summary.csv`
- `tab_m1_1_traj_heading_summary.csv`
- `tab_m1_1_traj_critical_summary.csv`
- `tab_m1_1_parameter_summary.csv`

### 5.3 结果说明

本部分用于固化第四章实验对象与轨迹基线的构造方式。

首先，以保护圆盘表示任务防护区域，以外层进入边界表示目标进入位置集合。随后，在进入边界上构造三类来袭样本：

- **nominal 族**：表示名义进入方向下的基准样本；
- **heading 族**：在 nominal 基础上加入有限航向偏差，用于表征进入方向扩展后的场景变化；
- **critical 族**：用于描述危险几何情形，包括贴近轨道面方向与小交会角两类典型情形。

在目标轨迹构造方面，基于统一的初始状态与控制模板生成开放环 HGV 轨迹样本库。由二维与三维图可见，nominal、heading 与 critical 三类轨迹在平面几何与空间形态上均存在清晰差异，从而为后续观测与最坏窗口分析提供了统一且具有代表性的输入样本。

------

## 6. M1.2：单层 Walker 观测基线

### 6.1 图片

![代表性可见性与 LOS 几何](https://chatgpt.com/deliverables/milestone_m1/figs/fig_m1_2_visibility_case.png)

### 6.2 表格

- `tab_m1_2_walker_baseline.csv`
- `tab_m1_2_visibility_case_summary.csv`

### 6.3 结果说明

本部分用于固化单层 Walker 观测基线及其与目标轨迹样本的耦合关系。

在统一时间网格下，完成了：

- Walker 基线星座传播；
- 目标—卫星可见性判定；
- 可见卫星数量统计；
- 双星覆盖时段识别；
- 最小 LOS 交会角的几何分析。

从代表性样本图可以看出，在名义情况下，目标在大部分时段内能够维持 2 星及以上可见；但在轨迹后段，可见星数量开始下降，最小 LOS 交会角也随之退化。这表明：**覆盖存在并不必然意味着观测几何稳定**。因此，仅使用覆盖类指标不足以评价连续托管意义下的基线可行性，还必须进一步分析窗口层面的几何退化。

------

## 7. M1.3：最坏窗口谱退化与门槛化

### 7.1 图片

![代表性样本的最坏窗口谱扫描](https://chatgpt.com/deliverables/milestone_m1/figs/fig_m1_3_window_case.png)

![最坏窗口谱在不同场景族中的分布](https://chatgpt.com/deliverables/milestone_m1/figs/fig_m1_3_window_family.png)

![最坏窗口判据下的通过率](https://chatgpt.com/deliverables/milestone_m1/figs/fig_m1_3_margin.png)

### 7.2 表格

#### 谱统计

- `tab_m1_3_family_summary.csv`
- `tab_m1_3_heading_summary.csv`
- `tab_m1_3_critical_summary.csv`

#### 门槛化统计

- `tab_m1_3_margin_family.csv`
- `tab_m1_3_margin_heading.csv`
- `tab_m1_3_margin_critical.csv`

### 7.3 结果说明

本部分用于固化最坏窗口谱分析与门槛化判定结果。

首先，对窗口信息矩阵随窗口起点 (t_0) 的变化进行扫描，提取代表性样本在固定窗口长度下的谱底变化曲线。由代表性曲线可见，窗口谱底在前中段维持较高水平，但在后段迅速衰减并最终接近零。这说明即使整体覆盖并未立即完全失效，局部时间窗口内仍可能出现显著观测退化，因此必须显式考察最坏窗口。

随后，对所有样本的最坏窗口谱底进行族级统计。可以看到，nominal 与 heading 两类样本都表现出明显偏态分布：多数样本贴近较低谱底区间，少数样本则具有较高谱底。critical 样本整体更接近低值区，说明其最坏窗口脆弱性更为突出。

进一步地，引入门槛化指标
[
D_G = \frac{\lambda_{\min}^{\mathrm{worst}}}{\gamma_{\mathrm{req}}},
]
并据此统计通过率。结果表明：

- nominal 族仅部分通过；
- heading 族通过率进一步下降；
- critical 族在当前门槛下全部失败。

从 heading offset 的通过率分布看，当前基线在 (0^\circ) 方向表现最好，而在 (\pm 30^\circ) 附近通过率降为零，在 (\pm 60^\circ) 附近仍仅能部分通过。这表明单层 Walker 基线对来袭方向具有显著敏感性，不具备面向全场景的统一稳健性。

### 7.4 关于对数纵轴显示的说明

为展示最坏窗口谱底的强偏态分布，`fig_m1_3_window_family.png` 使用了对数纵轴。
对于数值为零的样本，图中仅为显示目的将其截断至固定下界（显示 floor），以避免对数轴无法绘制。该处理**不改变原始统计结果**，仅用于可视化。

------

## 8. 阶段性结论

基于当前 Milestone M1，可以得到如下阶段性结论：

1. 已完成第四章实验对象的统一定义，建立了保护圆盘—进入边界—目标轨迹族的场景体系；
2. 已构建单层 Walker 基线与目标轨迹样本的观测分析链路，证明 nominal、heading 与 critical 在覆盖与 LOS 几何层面均存在显著差异；
3. 已完成最坏窗口谱扫描，说明局部时间窗口的观测退化是单层基线脆弱性的主要体现形式之一；
4. 已通过门槛化指标给出族级通过率统计，结果显示 nominal 仅部分通过、heading 进一步退化、critical 全部失败；
5. 因此，单层 Walker 只能作为第四章的**基线构型**，而不能直接视为面向全场景任务的稳健解。

------

## 9. 下一步

基于 M1 的结果，下一步建议进入：

- **Stage05A：单层 Walker 的 (h-i) 切片扫描**

其目标是回答：

1. 是否存在更稳健的单层 Walker 参数区间；
2. 单层结构能否通过参数调整部分补救最坏窗口脆弱性；
3. 若不能，则是否需要进一步进入双层或几何补强设计。

------

## 10. Git 跟踪建议

建议纳入 git：

- `milestones/milestone_m1_export_baseline.m`
- `milestones/milestone_m1_export_baseline.md`
- `deliverables/milestone_m1/tables/*.csv`
- `deliverables/milestone_m1/notes/*.md`
- `deliverables/milestone_m1/figs/*.png`

建议忽略：

- `results/cache/`
- `results/logs/`
- `results/figs/` 中的中间开发结果