# Phase 5 summary

## 1. Scope

This note summarizes the current Chapter 5 development status up to Phase 5D.

Covered phases:

- Phase 5-pre: dual-scene reference layer
- Phase 5A: geometry-aware mg / future geometry floor
- Phase 5B: explicit phi threshold and volatility-aware evaluation
- Phase 5C: threshold-sensitive risk objective
- Phase 5D: longest-bad-run-first objective

---

## 2. Scene presets

### stress96
- meaning: pressure scene below the Stage05 nominal-family static reference level
- constellation:
  - i = 70 deg
  - P = 8
  - T = 12
  - N_s = 96

### ref128
- meaning: static-reference-aligned scene at the same (i, P) but higher total satellite count
- constellation:
  - i = 70 deg
  - P = 8
  - T = 16
  - N_s = 128

---

## 3. Main file chain

### Configuration
- `ch5_dualloop/params/default_ch5_params.m`
- `ch5_dualloop/params/apply_ch5_scene_preset.m`

### Real object construction
- `ch5_dualloop/scenario/build_ch5_target_profile.m`
- `ch5_dualloop/scenario/build_ch5_truth_from_stage02_engine.m`
- `ch5_dualloop/scenario/build_ch5_satbank_from_stage03_engine.m`
- `ch5_dualloop/scenario/build_ch5_candidates_from_stage03_engine.m`
- `ch5_dualloop/scenario/build_ch5_case.m`

### Baselines
- `ch5_dualloop/policies/policy_tracking_dynamic.m`
- `ch5_dualloop/policies/policy_static_hold.m`
- `ch5_dualloop/policies/policy_custody_singleloop.m`

### Outer-loop B / single-loop custody objective
- `ch5_dualloop/outer_loop_B/compute_mg_series.m`
- `ch5_dualloop/outer_loop_B/compute_ttl_series.m`
- `ch5_dualloop/outer_loop_B/compute_phi_window.m`
- `ch5_dualloop/outer_loop_B/build_window_objective_singleloop.m`

### Metrics and runners
- `ch5_dualloop/metrics/eval_tracking_metrics.m`
- `ch5_dualloop/metrics/eval_custody_metrics.m`
- `ch5_dualloop/runners/run_ch5_phase5pre_scene_compare.m`
- `ch5_dualloop/runners/run_ch5_phase5_singleloop_custody.m`

### Outputs
- `outputs/cpt5/phase5pre/...`
- `outputs/cpt5/phase5/...`

---

## 4. Parameter evolution

### Phase 5-pre
Goal:
- establish two chapter-5 scene presets:
  - stress96
  - ref128

### Phase 5A
Main change:
- mg becomes geometry-aware
- future objective uses future geometry floor

### Phase 5B
Main change:
- explicit phi threshold
- custody evaluation no longer uses the old fixed threshold=1 interpretation

Key parameter:
- `custody_phi_threshold = 0.45`

### Phase 5C
Main change:
- threshold-sensitive gap / outage penalties

Key parameters:
- `custody_gap_weight = 1.20`
- `custody_outage_weight = 0.80`

### Phase 5D
Main change:
- longest-bad-run-first objective

Key parameters:
- `custody_longest_bad_weight = 100.0`
- `custody_worst_gap_weight = 10.0`
- `custody_outage_frac_weight = 3.0`
- `custody_mean_gap_weight = 1.0`
- `custody_mean_future_weight = 0.05`
- `custody_switch_weight = 0.20`

---

## 5. Results by phase

### 5.1 Phase 5-pre
Observed:
- `ref128` has higher candidate richness than `stress96`
- both scenes are valid for chapter-5 comparison
- scene-layer construction is complete

Engineering conclusion:
- scene layer is no longer the bottleneck

### 5.2 Phase 5A
Observed:
- phi no longer saturates near 1
- however evaluation threshold was still mismatched
- outage metrics were not yet interpretable

Engineering conclusion:
- geometry-aware direction is correct
- custody metric semantics required repair

### 5.3 Phase 5B
Observed:
- outage metrics became interpretable after explicit threshold support
- C still did not clearly outperform T

Engineering conclusion:
- metric semantics repaired
- objective still too weak

### 5.4 Phase 5C
Observed:
- C stopped catastrophic degradation
- C could reduce outage ratio somewhat
- but still did not improve q_worst or longest outage

Engineering conclusion:
- risk-sensitive direction is useful
- but still mostly reduces fragmented outages

### 5.5 Phase 5D
Observed final multi-round results:

#### stress96
Tracking T:
- mean_rmse = 0.9115
- q_worst = 0.0500
- phi_mean = 0.5550
- outage_ratio = 0.0162
- longest_outage_steps = 8

Single-loop C:
- mean_rmse = 1.0004
- q_worst = 0.0500
- phi_mean = 0.5288
- outage_ratio = 0.0125
- longest_outage_steps = 8

Interpretation:
- C reduces outage ratio
- C does not raise the worst floor
- C does not shorten the longest bad chain

#### ref128
Tracking T:
- mean_rmse = 0.9115
- q_worst = 0.0500
- phi_mean = 0.5701
- outage_ratio = 0.0175
- longest_outage_steps = 8

Single-loop C:
- mean_rmse = 1.0004
- q_worst = 0.0500
- phi_mean = 0.5278
- outage_ratio = 0.0137
- longest_outage_steps = 8

Interpretation:
- same pattern as stress96
- single-loop C mainly lowers small-fragment outage frequency
- but still cannot improve worst window floor or longest outage length

---

## 6. Overall current conclusion

Stable conclusions up to Phase 5D:

1. S is insufficient and clearly worse than T.
2. A single-loop custody-oriented method C is not useless:
   it can reduce outage ratio.
3. However, the current single-loop C still cannot improve:
   - q_worst
   - longest_outage_steps
4. Therefore, the engineering justification for Phase 6 is now clear:

> single-loop local window scoring can reduce fragmented outage,
> but cannot proactively cut future bad chains;
> an outer loop is needed to provide predictive prior / bad-chain avoidance.

---

## 7. Recommended next step

Proceed to Phase 6 minimal dual-loop custody scheduling.

Target:
- keep current inner-loop selection framework
- add an outer-loop prior update
- compare T / C / CK-min on:
  - q_worst
  - outage_ratio
  - longest_outage_steps

Success criterion:
- CK-min should improve at least one of:
  - q_worst
  - longest_outage_steps
  relative to both T and C in at least one scene.
