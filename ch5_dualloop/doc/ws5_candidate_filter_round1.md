# WS-5-R1

## Goal
Introduce template-guided candidate filtering before outerB baseline scoring.

## Scope
This round keeps the baseline objective unchanged.
It only:
- builds candidate local-frame features
- compares them to the matched template prototype
- keeps top-K closest candidates
- then runs the existing baseline outerB score

## Notes
- prior still enters first via reference selection
- candidate filtering is applied only when:
  - prior_enable = true
  - template_filter_enable = true
- top-K rule is used in round 1
