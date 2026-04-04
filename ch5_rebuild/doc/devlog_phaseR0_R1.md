# Chapter 5 Rebuild Development Log — Phase R0 to Phase R1

## 1. Scope

This log records the actual development process and smoke-test results for Chapter 5 rebuild:

- Phase R0: bootstrap from Chapter 4 stage outputs
- Phase R1: minimal bubble-state pipeline

The current goal is **not** to prove the final Chapter 5 method, but to establish a minimal, computable, time-indexed observability-bubble state chain.

---

## 2. Phase R0 — Bootstrap from Chapter 4

### 2.1 Objective

Phase R0 was designed to initialize the new `ch5_rebuild/` branch without modifying the legacy Chapter 4 stage pipeline.

The intended mapping is:

\[
\mathcal B:
(\text{Stage04 outputs},\ \text{Stage05 outputs},\ \text{default params})
\mapsto
(\theta^\star,\theta^+,\eta_{\mathrm{sens}}^{(0)},\xi^\star,\gamma_{\mathrm{req}})
\]

where:

- \(\theta^\star\): static minimum feasible constellation
- \(\theta^+\): slightly redundant feasible constellation
- \(\eta_{\mathrm{sens}}^{(0)}\): baseline sensor profile
- \(\xi^\star\): representative target case
- \(\gamma_{\mathrm{req}}\): Chapter 5 bubble threshold

### 2.2 Implemented files

Phase R0 introduced:

- `ch5_rebuild/params/default_ch5r_params.m`
- `ch5_rebuild/bootstrap/bootstrap_ch5r_from_stage04_stage05.m`
- `ch5_rebuild/bootstrap/load_latest_stage04_cache.m`
- `ch5_rebuild/bootstrap/load_latest_stage05_cache.m`
- `ch5_rebuild/bootstrap/select_static_min_solution.m`
- `ch5_rebuild/bootstrap/select_static_plus_solution.m`
- `ch5_rebuild/bootstrap/select_representative_target_case.m`
- `ch5_rebuild/bootstrap/build_ch5r_params_from_bootstrap.m`
- `ch5_rebuild/runners/run_ch5r_phase0_bootstrap_smoke.m`

### 2.3 Actual smoke result

The formal R0 smoke runner successfully loaded Stage04 and Stage05 search cache:

- Stage04 source: `stage04_window_worstcase_20260331_194610.mat`
- Stage05 source: `stage05_nominal_walker_search_20260331_194610.mat`
- Stage05 kind: `search`

The extracted bootstrap parameters were:

#### theta_star

- \(h = 1000\ \mathrm{km}\)
- \(i = 50^\circ\)
- \(P = 12\)
- \(T = 8\)
- \(F = 1\)
- \(N_s = P T = 96\)
- \(D_G = 1.6330\)
- pass ratio = 1
- case id = `N01`

#### theta_plus

- \(h = 1000\ \mathrm{km}\)
- \(i = 60^\circ\)
- \(P = 10\)
- \(T = 10\)
- \(F = 1\)
- \(N_s = 100\)
- \(D_G = 1.2352\)
- pass ratio = 1
- case id = `N01`

#### gamma_req

\[
\gamma_{\mathrm{req}} = 19748.4536074
\]

### 2.4 Interpretation

This result means that Chapter 5 is no longer initialized from hand-filled parameters. Instead, it is now explicitly anchored to Chapter 4 static design outputs.

The most important implication is:

- Chapter 5 is now built on a **strong static-feasible baseline**
- It is **not** built on an obviously under-provisioned constellation
- This supports the Chapter 5 narrative:
  static feasibility does not automatically imply bubble-free operation

---

## 3. Phase R1 — Minimal bubble-state pipeline

### 3.1 Objective

Phase R1 was intended to establish the minimal Chapter 5 state chain:

\[
\text{case}
\rightarrow
Y_W(t)
\rightarrow
\lambda_{\min}(Y_W(t))
\rightarrow
\text{bubble flag}
\rightarrow
\text{bubble segment}
\]

At this stage:

- no dynamic scheduling is used
- no filter loop is used
- no dual-loop structure is used
- no full physical observation model is used

The goal is only to verify that the Chapter 5 core object, namely the **observability bubble**, can be represented and computed.

### 3.2 Implemented files

Phase R1 introduced:

- `ch5_rebuild/scenario/build_ch5r_case.m`
- `ch5_rebuild/state/eval_window_information.m`
- `ch5_rebuild/state/eval_bubble_state.m`
- `ch5_rebuild/state/package_state_trace.m`
- `ch5_rebuild/runners/run_ch5r_phase1_smoke.m`

### 3.3 Core principle

At each discrete time \(t_k\), a synthetic positive-definite information matrix is constructed:

\[
Y_k \in \mathbb{R}^{6\times 6}
\]

This is not yet a physically reconstructed information matrix from real line-of-sight measurement equations. It is a deterministic synthetic proxy used to validate the pipeline interface.

Then a rolling-window information matrix is accumulated as:

\[
Y_W(k)=\sum_{j=s_0(k)}^{k} Y_j
\]

The current window length is 60 s, with 10 s step size.

Bubble detection is defined by the minimum eigenvalue criterion:

\[
\lambda_{\min}(Y_W(k)) < \gamma_{\mathrm{req}}
\]

If the inequality holds, the corresponding window is marked as an observability bubble.

This means that the bubble notion is not interpreted as "no observation at all", but as:

> the weakest information direction in the window has dropped below the required level.

This is consistent with the intended Chapter 5 interpretation of a local directional information void, rather than a simple binary visibility gap.

---

## 4. R1 smoke-test results

### 4.1 Final positive-case smoke result

The final R1 smoke output was:

- target case = `N01`
- theta_star \(N_s = 96\)
- window length = 60 s
- \(\gamma_{\mathrm{req}} = 19748.4536074\)
- minimum rolling-window eigenvalue:

\[
\min_k \lambda_{\min}(Y_W(k)) = 9654.88347159
\]

- bubble steps = 2
- bubble time = 20 s
- longest bubble = 20 s

### 4.2 Interpretation of the result

Since

\[
9654.88347159 < 19748.4536074
\]

the Chapter 5 R1 pipeline successfully detected a positive bubble event.

The result also shows that the bubble is **local rather than global**:

- only 2 discrete steps are below threshold
- with 10 s step size, total bubble duration is 20 s
- the bubble appears as one short contiguous bubble segment

This is important. If the entire horizon were below threshold, the result would only indicate that the whole configuration was globally inadequate. The current result is more aligned with the intended Chapter 5 problem:

> a static-feasible design may still produce a local bad window during operation.

### 4.3 First few state values

The first few rolling-window minimum eigenvalues were approximately:

\[
[9655,\ 19257,\ 28754,\ 38062,\ 47053]
\]

with threshold

\[
\gamma_{\mathrm{req}} \approx 19748
\]

Therefore:

- the first point is below threshold
- the second point is still below threshold but close to threshold
- subsequent points rise above threshold

This is consistent with the bubble flags:

\[
[1,\ 1,\ 0,\ 0,\ 0,\dots]
\]

Hence the R1 state chain is internally consistent:

\[
\lambda_{\min}(Y_W)\uparrow
\Rightarrow
\text{bubble flag changes from 1 to 0}
\]

---

## 5. Unified state trace

The current R1 state trace includes:

- `time_s`
- `lambda_min`
- `gamma_req`
- `is_bubble`
- `bubble_depth`
- `window_start_idx`
- `window_end_idx`
- `meta`

This is the first stable state interface for Chapter 5.

In particular:

### 5.1 lambda_min

\[
\lambda_{\min}(Y_W(k))
\]

is the core scalar representing the weakest information direction in the rolling window.

### 5.2 is_bubble

\[
b(k)=\mathbf{1}\{\lambda_{\min}(Y_W(k))<\gamma_{\mathrm{req}}\}
\]

turns the spectral state into a discrete event sequence.

### 5.3 bubble_depth

\[
d(k)=\max\left(0,\gamma_{\mathrm{req}}-\lambda_{\min}(Y_W(k))\right)
\]

quantifies how far the system falls below the threshold. This will be a direct input to later bubble metrics.

### 5.4 window_start_idx / window_end_idx

These fields preserve the fact that bubble detection is window-based rather than instantaneous. This is essential for the custody-oriented interpretation of Chapter 5.

---

## 6. What this result proves, and what it does not prove

### 6.1 What is proved at this stage

The current result proves that:

1. the Chapter 5 rebuild now has an independent bootstrap path from Chapter 4
2. the observability-bubble notion has been turned into a computable engineering state
3. a local bubble event can be detected, segmented, timed, and packaged
4. the minimal Chapter 5 pipeline is now operational

### 6.2 What is not yet proved

The current result does **not** yet prove that:

1. the final Chapter 5 scheduling method is effective
2. the current bubble profile is physically realistic
3. real measurement geometry has already been reconstructed
4. requirement-margin failure has been linked quantitatively
5. dynamic repair or bubble suppression is already demonstrated

Therefore, this phase should be interpreted as:

> a mechanism-level and interface-level validation of the Chapter 5 bubble-state pipeline

rather than a final scientific performance result.

---

## 7. Development conclusion after R1

After R1, the Chapter 5 rebuild now contains the minimal stable backbone:

- `default_ch5r_params`
- `bootstrap_ch5r_from_stage04_stage05`
- `build_ch5r_case`
- `eval_window_information`
- `eval_bubble_state`
- `package_state_trace`
- `run_ch5r_phase0_bootstrap_smoke`
- `run_ch5r_phase1_smoke`

This means that the Chapter 5 rebuild has completed the transition:

\[
\text{concept}
\rightarrow
\text{computable state}
\rightarrow
\text{time-indexed bubble trace}
\]

This is the necessary basis for the next stage, namely **Phase R2**, which will introduce unified metrics on top of the existing state trace.

---

## 8. Next step

The next phase should not jump directly into dynamic scheduling. The recommended next step is:

### Phase R2 — minimal metric layer

First implement:

- `eval_bubble_metrics.m`
- `eval_requirement_margin.m`
- `package_ch5r_result.m`

with bubble metrics as the first priority, because they directly inherit the current R1 state trace.
