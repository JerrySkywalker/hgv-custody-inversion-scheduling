# ch5_rebuild

本目录用于第五章新主线重建，当前已完成 **Phase R0-R3** 的收口，并已启动 **Phase R4**。

## 当前状态

### R0
- bootstrap from Stage04 / Stage05

### R1
- minimal case / window information / bubble state

### R2
- minimal metric layer:
  - bubble
  - custody
  - RMSE proxy
  - requirement proxy
  - cost interface

### R3
- first formal baseline:
  - `static_hold`
  - result bundle
  - timeline / failure-case plots

### R4
- second baseline started:
  - `tracking_greedy`
  - `select_satellite_set_tracking_greedy`
  - `run_ch5r_phase4_tracking_baseline`

## MATLAB 使用

```matlab
addpath(fullfile(pwd,'ch5_rebuild'));
addpath(fullfile(pwd,'ch5_rebuild','params'));
addpath(fullfile(pwd,'ch5_rebuild','bootstrap'));
addpath(fullfile(pwd,'ch5_rebuild','scenario'));
addpath(fullfile(pwd,'ch5_rebuild','state'));
addpath(fullfile(pwd,'ch5_rebuild','metrics'));
addpath(fullfile(pwd,'ch5_rebuild','policies'));
addpath(fullfile(pwd,'ch5_rebuild','allocator'));
addpath(fullfile(pwd,'ch5_rebuild','plots'));
addpath(fullfile(pwd,'ch5_rebuild','runners'));

out0 = run_ch5r_phase0_bootstrap_smoke();
out1 = run_ch5r_phase1_smoke();
out2 = run_ch5r_phase2_metrics_smoke();
out3 = run_ch5r_phase3_static_bubble_demo();
out4 = run_ch5r_phase4_tracking_baseline();
