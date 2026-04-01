# Phase 9 summary

## Goal
Sweep the custody window length T_w for methods:
- T
- C
- CK

and compare:
- q_worst_window
- phi_mean
- outage_ratio
- longest_outage_steps
- mean_rmse

## Current official evaluation
- q_worst_window is the official worst-window metric
- q_worst_point is diagnostic only

## Scenes
- stress96
- ref128

## Default sweep grid
- [10 20 30 40 60 80]

## Expected value
This phase should produce the main parameter-sensitivity curves of Chapter 5.
