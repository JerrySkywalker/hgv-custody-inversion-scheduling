# WS-4-R1 / R2

## Goal
Integrate template matching into reference selection, not into additive score bonus.

## Round 1
WS-4-R1 verified the interface path:
- template library
- match output
- ref_ids
- selected_ids

But it also exposed a self-match issue:
the current visible multi-set was included in the library, so best_distance became 0
and ref_ids collapsed to visible_ids.

## Round 2
WS-4-R2 fixes this by:
- building the template library from pair prototypes only
- using the current visible multi-set as query

Therefore:
- query and library are separated
- self-match is avoided
- ref_ids become an external structural reference

## Notes
This round still does not change:
- build_window_objective_dualloop baseline formula
- candidate filtering
- full structural prior objective
