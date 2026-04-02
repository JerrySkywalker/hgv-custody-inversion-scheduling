# Phase7A Status

## Current role

`Phase7A` currently serves as the formal dynamic baseline of Chapter 5.

The working baseline method is:

- `CK` = custody-oriented dual-loop baseline

This status is now explicit and should be used consistently in later development and writing.

---

## Why Phase7A is the baseline

Current evidence shows that `CK` already provides a stable and meaningful improvement structure relative to `C`, especially on:

- worst-window custody quality
- outage behavior
- dynamic custody continuity interpretation

At the same time, newer exploratory integrations based on direct prior/filter insertion have not yet shown a stable improvement over `CK`.

Therefore, `CK` must remain the comparison anchor for all next-stage experiments.

---

## Allowed comparison targets after this note

Later stages may compare against:

- `C`
- `CK`
- `CK + state-machine switching`
- `CK + proposal guidance`
- `CK + state-machine-constrained template guidance`

But should no longer treat direct stepwise prior/filter variants as the default next baseline.

---

## Practical rule

If a new method is developed later, its first question is not:

- "is it better than C?"

but:

- "does it improve on CK without breaking continuity?"

That is the formal Phase7A status going forward.
