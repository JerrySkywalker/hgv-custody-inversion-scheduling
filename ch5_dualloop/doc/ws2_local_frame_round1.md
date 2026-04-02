# WS-2-R1

## Goal
Add a stable local-frame extractor on top of real chapter-5 caseData.

## Scope
This round only extracts local structural geometry from:
- caseData.truth.r_eci_km
- caseData.truth.vx/vy/vz
- caseData.satbank.r_eci_km

No Phase08 integration in this round.

## Local frame
A target-centered orthonormal frame is built from target ECI position and velocity:
- e_r
- e_h
- e_theta

## Output quantities
- baseline_km
- Bxy_cand
- Ruse
- rel_local_km

## Notes
Ruse is set equal to Bxy_cand in round 1.
Further refinement is deferred to later rounds.

## Input compatibility
extract_candidate_local_features supports:
- cell candidate lists
- numeric matrix candidate lists
- struct arrays with field ids or mask
- single numeric vector
- binary mask rows of width Ns
