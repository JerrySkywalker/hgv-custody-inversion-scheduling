# MB Final Round

This package is the final MB closure handoff for the MATLAB project.

## What is frozen
- startup/path now uses whitelist initialization with session reuse
- figure runtime is unified through the project figure manager
- MB exports now distinguish `fullRange` and `frontierZoom`
- expanded search, heatmap overcompute, and frontier refinement are integrated into the MB export chain
- strict Stage05 replica remains the validation anchor

## Final-round roots
- strict replica fresh root: `outputs/milestones/MB_20260322_finalr1_strict`
- baseline fresh root: `outputs/milestones/MB_20260322_finalr1_baseline`
- delivery bundle: `outputs/milestones/MB_final_round_delivery`

## Paper vs diagnostic
- paper-candidate figures should prefer `fullRange` as the primary pass-ratio figure
- `frontierZoom` is supplemental
- baseline `h=1000` comparison remains `diagnostic_only`

## Guarantees
- Stage05/06 original core files were not modified
- strict replica still matches the Stage05 reference with zero curve difference
