# WS-3-R1

## Goal
Build a minimal prototype-based template library from WS-2 local-frame features.

## Scope
This round does not touch the main chapter-5 policy chain.

## Feature vector
- num_sats
- baseline_km / 1000
- Bxy_cand / 1000
- Ruse / 1000
- mean_xy_radius_km / 1000

## Template family
Rule-based prototype family only in round 1:
- pair_compact
- pair_medium
- pair_wide
- multi_compact
- multi_wide

## Matching
Euclidean distance to template prototype.

## Notes
Round 1 intentionally avoids clustering.
The goal is to stabilize the template-library interface first.
