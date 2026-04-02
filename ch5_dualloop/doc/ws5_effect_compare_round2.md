# WS-5-R2

## Goal
Quantify the effect of template-guided reference selection and candidate filtering.

## Compared modes
1. baseline
   - no prior
   - no template filtering

2. reference_only
   - prior enabled
   - template-guided ref_ids
   - no candidate filtering

3. reference_plus_filter
   - prior enabled
   - template-guided ref_ids
   - template-guided top-K candidate filtering

## Export
For each mode, export:
- selected_ids
- ref_ids
- match result
- filter result
- num_all_candidates
- num_kept_candidates

## Notes
This round does not change the baseline objective formula.
It only quantifies what template selection and filtering changed.
