# Phase 7A / 7B summary

## What earlier diagnostics proved
The support-based proxy can screen out obviously bad sets, but it cannot
discriminate among many dual-satellite sets that all have:
- longest_single_support = 0
- single_support_ratio = 0
- zero_support_ratio = 0

As a result, residual terms such as template/switch preference dominate
the final choice.

## Phase 7B-pre outcome
- safe fallback to C
- warn/trigger geometry tie-break
This already reduced the custody gap, proving geometric discrimination helps.

## Phase 7B formal change
Geometry is no longer just a tie-break.
It is promoted into the main objective in warn/trigger:
- reward larger angle-only information lambda-min
- reward larger LOS crossing angle
while keeping:
- support-structure constraints
- weak hard gates
- safe fallback to C

## Purpose
This is the first formal outerB objective that combines:
- support-based custody protection
- geometric observability quality
in one score.
