# Phase 7A / 7B-pre summary

## What the diagnostics proved
The support-based proxy can screen out obviously bad sets, but it cannot
discriminate among many dual-satellite sets that all have:
- longest_single_support = 0
- single_support_ratio = 0
- zero_support_ratio = 0

As a result, residual terms such as template/switch preference dominate
the final choice, producing a systematic C-vs-CK divergence.

## Phase 7B-pre change
- safe mode falls back directly to C
- warn/trigger keep dual-satellite support-first selection
- after support screening, use geometric tie-break:
  1) shorter longest_single_support
  2) smaller single_support_ratio
  3) larger angle-only information lambda-min
  4) larger LOS crossing angle
  5) lower residual score

## Reused stage ideas
- Stage03 style LOS crossing-angle geometry
- Stage04 style angle-only information increment

## Purpose
This is the first revision that explicitly adds geometric discrimination
among support-equivalent dual-satellite sets.
