# ch5_rebuild

本目录用于第五章新主线重建，当前已完成 **Phase R0-R3** 的收口，并进入 **R4b.1**。

## 当前状态

### R0
- bootstrap from Stage04 / Stage05

### R1
- minimal case / window information / bubble state
- Stage02/03 wrapper placeholders

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

### R4b.1
- second baseline:
  - `tracking_greedy`
  - hysteresis switching
  - policy selection feeds back into information proxy

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

out3 = run_ch5r_phase3_static_bubble_demo();
out4 = run_ch5r_phase4_tracking_baseline();
