# Phase08 Continuous Prior Integration

## Purpose
Replace hard region/template logic with continuous geometric prior terms.

## Prior terms
- Fragility penalty
- Box-scale deviation penalty
- Geometry-radius consistency penalty

## Current smoke scope
- Weak / mid / strong geometry representative samples
- Stage15-H2 mapped prior
- Continuous penalty synthesis
- Output logging for later CK integration

## Next step
Integrate prior_cost into CK/outerA candidate scoring and compare:
- CK
- CK + fragility
- CK + full continuous prior
