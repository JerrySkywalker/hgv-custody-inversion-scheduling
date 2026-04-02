# WS-4-R1

## Goal
Integrate template matching into reference selection, not into additive score bonus.

## Scope
This round does not change:
- build_window_objective_dualloop baseline formula
- policy_custody_dualloop_koopman main loop

It only changes:
- prior library entry format
- match_reference_prior output
- select_satellite_set_custody_dualloop reference-id selection path

## Logic
1. Build local-frame query feature from current visible set
2. Match template library
3. Use matched template prototype ids as ref_ids
4. Keep the rest of outerB baseline scoring unchanged

## Notes
This round is a template-guided reference-selection prototype.
Candidate filtering is deferred to WS-5.
