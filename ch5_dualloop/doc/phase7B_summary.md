# Phase 7B summary

## Goal
Ablate the current CK formal method to identify which component is driving the improvement.

## Minimal ablation set
- C baseline
- CK full
- CK without geometry

## Official evaluation
- q_worst_window is the official worst-window metric
- q_worst_point is diagnostic only

## Main question
Does geometry entering the outerB main objective materially improve:
- q_worst_window
- phi_mean
- longest_outage_steps
while preserving good tracking RMSE?

---

## Results snapshot

### stress96
- C:
  - q_worst_window = 0.376955
  - phi_mean = 0.528834
  - outage_ratio = 0.012484
  - longest_outage_steps = 8
  - mean_rmse = 1.000400
- CK full:
  - q_worst_window = 0.426186
  - phi_mean = 0.531738
  - outage_ratio = 0.022472
  - longest_outage_steps = 8
  - mean_rmse = 0.974615
- CK without geometry:
  - q_worst_window = 0.355103
  - phi_mean = 0.479846
  - outage_ratio = 0.048689
  - longest_outage_steps = 34
  - mean_rmse = 0.974615

Interpretation:
- Removing geometry causes a large collapse in custody quality.
- RMSE stays almost unchanged.
- Therefore, geometry is not mainly improving tracking RMSE; it is mainly correcting the custody decision axis.

### ref128
- C:
  - q_worst_window = 0.398767
  - phi_mean = 0.527832
  - outage_ratio = 0.013733
  - longest_outage_steps = 8
  - mean_rmse = 1.000400
- CK full:
  - q_worst_window = 0.434412
  - phi_mean = 0.559872
  - outage_ratio = 0.021223
  - longest_outage_steps = 8
  - mean_rmse = 0.977449
- CK without geometry:
  - q_worst_window = 0.340933
  - phi_mean = 0.502450
  - outage_ratio = 0.044944
  - longest_outage_steps = 33
  - mean_rmse = 0.977449

Interpretation:
- The same pattern repeats in ref128.
- Geometry is a necessary term for preventing long custody failures.
- Without geometry, CK degenerates into a tracking-preserving but custody-degrading policy.

---

## Phase 7B conclusion
The minimal ablation already supports a strong conclusion:

Geometry is not a cosmetic add-on in CK.  
It is a necessary component of the outerB main objective.

More specifically:
- geometry materially lifts q_worst_window
- geometry materially lifts phi_mean
- geometry suppresses longest continuous outage segments
- geometry has little effect on RMSE, which remains nearly unchanged

Thus, the main role of geometry is to improve custody-oriented selection quality rather than to reshape tracking precision.

## Status
Phase 7B minimal ablation can be considered completed.
Optional future add-ons:
- CK without safe fallback
- CK without mode switching
