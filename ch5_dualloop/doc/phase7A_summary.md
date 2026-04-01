# Phase 7A / 7B / eval-fix summary

## Why this eval-fix is needed
The latest 7B formal results showed a suspicious pattern:
- phi_mean improved
- longest_outage_steps matched C
- outage_ratio was only slightly worse
- but q_worst became 0 in ref128

This strongly suggests that the current q_worst may still reflect a pointwise minimum,
which is not fully aligned with the chapter-5 "worst-window" interpretation.

## Eval-fix change
Keep both:
- q_worst_point  = pointwise minimum of phi_series
- q_worst_window = rolling-window minimum of phi_series mean

Then define:
- q_worst = q_worst_window

## Purpose
This allows direct diagnosis of whether the old q_worst=0 behavior came from
isolated point dips or from truly bad windows.
