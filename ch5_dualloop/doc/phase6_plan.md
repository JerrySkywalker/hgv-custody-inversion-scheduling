# Phase 6 plan

## Goal

Build a minimal dual-loop custody method CK-min.

### Motivation
Phase 5 showed:
- T is strong
- C can reduce outage ratio
- but C cannot improve q_worst or longest_outage_steps consistently

Therefore Phase 6 introduces an outer loop.

---

## Minimal Phase 6 structure

### Outer loop A
- update every fixed number of steps
- build a future-risk-aware prior map for all satellites
- prefer satellites that remain visible longer and stay closer to target

### Inner loop B
- keep the existing single-loop custody selector
- add the outer prior bonus to the local selection score

---

## Main files

- `outer_loop_A/compute_outer_prior_map.m`
- `allocator/select_satellite_set_custody_dualloop.m`
- `policies/policy_custody_dualloop_min.m`
- `plots/plot_custody_phi_timeline_three.m`
- `plots/plot_custody_summary_bars_three.m`
- `runners/run_ch5_phase6_dualloop_min.m`

---

## Success criterion

At least one scene should show that CK-min improves one of:
- q_worst
- longest_outage_steps

relative to both T and C.
