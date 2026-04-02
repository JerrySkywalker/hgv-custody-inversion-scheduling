# WS-5-R5

## Goal
Finalize working parameter presets and export cleaner plots for reporting and writing.

## Fixed presets
- aggressive   : topK=2, cap=5
- balanced     : topK=4, cap=10
- conservative : topK=8, cap=20

## Exported content
- per-profile summary text
- recommendation block
- publication-style plots:
  - decision-change vs baseline
  - decision-change vs reference-only
  - average compression ratio
  - average kept candidate count
  - profile map

## Recommended default
- ref128   -> balanced
- stress96 -> balanced

## Notes
This round is still analysis/export only.
No baseline objective formula is changed.
