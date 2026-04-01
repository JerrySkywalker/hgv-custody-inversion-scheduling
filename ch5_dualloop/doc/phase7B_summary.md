# Phase 7B summary

## Goal
Ablate the current CK formal method to identify which component is driving the improvement.

## Minimal ablation set
- C baseline
- CK full
- CK without geometry

## Current evaluation convention
- official worst metric: q_worst_window
- pointwise minimum q_worst_point is diagnostic only

## Main question
Does geometry entering the outerB main objective materially improve:
- q_worst_window
- phi_mean
- longest_outage_steps
while preserving good tracking RMSE?
