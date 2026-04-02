# Phase8 Negative Result Note

## Scope

This note records the current negative result from the latest Phase8 prior integration tests.

It exists so that the engineering branch does not keep revisiting the same disproven assumption.

---

## Tested variants

The latest Phase8 integration compared:

- `C`
- `CK`
- `CK-ref-only`
- `CK-prior-balanced`

where:

- `CK-ref-only` means reference selection enabled without template filtering
- `CK-prior-balanced` means balanced prior library with template guidance enabled

---

## Observed result 1: reference-only is too weak

For both tested scenes:

- `ref128`
- `stress96`

the result was:

- `CK-ref-only == CK`

This means reference selection alone is currently too weak to change the dynamic CK chain in any meaningful way.

Engineering interpretation:

- reference selection may still be useful as:
  - proposal
  - explanation
  - tie-break hint
- but it is not currently a standalone online decision mechanism

---

## Observed result 2: hard online template guidance is too strong

### ref128

Observed degradation relative to `CK`:

- `q_worst_window`: `0.43441 -> 0.32912`
- `phi_mean`: `0.55987 -> 0.44744`
- `outage_ratio`: `0.021223 -> 0.38327`
- `longest_outage_steps`: `8 -> 32`
- `switch_count`: `10 -> 48`

### stress96

Observed degradation relative to `CK`:

- `q_worst_window`: `0.42619 -> 0.38616`
- `phi_mean`: `0.53174 -> 0.48226`
- `outage_ratio`: `0.022472 -> 0.10612`
- `longest_outage_steps`: `8 -> 21`
- `switch_count`: `4 -> 18`

---

## Interpretation

The result does **not** mean the dissertation direction is wrong.

It means only that the following bridging route is currently unsuitable:

- static Chapter 4 template
- directly reused as stepwise hard online filtering in Chapter 5

This route over-constrains the dynamic system and creates excessive switching.

---

## Routing conclusion

Template prior knowledge should **not** be treated as the default per-step online hard filter.

Instead, it should be demoted to one of the following roles:

- proposal generator
- low-frequency reference
- diagnostics / explanation layer
- tie-break signal
- emergency-only guarded filter under trigger state

A future re-introduction is only allowed after a state-machine-based switching shell is implemented.
