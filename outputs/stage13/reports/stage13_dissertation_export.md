# Stage13 dissertation export

- recommended dt case: `dt_first_probe_P6T4F0`
- recommended dg case: `dg_first_probe_3`
- recommended dg case refined: `dg_micro_07`
- notes for MA extension: 优先考虑将 dt_first_probe_P6T4F0 作为 MA 基线邻域对照案例，用于说明基线附近时序/结构约束切换时的窗口曲线变化。
- notes for MB integration: 优先考虑将 dg_first_probe_3 作为 MB 任务几何主导反例，用于补充真值静态可行域之外的几何退化解释。
- dg refined review: dg_micro_07 相比 dg_first_probe_3 已从 joint collapse 改善为 DG 主导退化，当前 D_G^{worst}=0.792, D_A^{worst}=0.890, D_T^{worst}=1.000；其中 DT 保持在门槛，但 DA 仍同步明显下降，因此更适合作为备选/答辩材料，不建议立即正文 cherry-pick。
