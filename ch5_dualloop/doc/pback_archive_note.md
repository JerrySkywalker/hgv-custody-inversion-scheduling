# P-Back Archive Note

## Status

The `P-Back` numbering series is now frozen and archived.

It should be interpreted as a transition-period engineering label only.

---

## What P-Back achieved

The P-Back series completed the following transition tasks:

- stabilized the interpretation of `Phase7A` as the Chapter 5 baseline
- connected prior / template / filter logic into `Phase8`
- exposed the key negative result:
  direct stepwise hard prior/filter integration does not work as a stable default dynamic enhancement path

---

## Why P-Back is discontinued

P-Back should not continue because the later route is no longer a linear extension of the same assumption set.

The development direction has changed from:

- "connect static template directly into dynamic online filtering"

to:

- "rebuild the Chapter 4 -> Chapter 5 bridge around custody state-machine switching, guarded transitions, and weak template guidance"

Therefore, continuing to number later work as `P-Back-*` would be misleading.

---

## Replacement numbering

All later work should use the new `NX-*` numbering series.

Recommended mapping:

- baseline freeze and negative-result absorption -> `NX-0`
- CK ablation -> `NX-1`
- custody state machine switching -> `NX-2`
- online metric guard layer -> `NX-3`
- template proposal layer -> `NX-4`
- state-machine-constrained template guidance -> `NX-5`
- unified Chapter 5 experiment -> `NX-6`
- writing / release packaging -> `NX-7`

---

## Practical instruction

Do not create new `P-Back-*` files, runners, or docs after this note.

Preserve old P-Back artifacts only as historical engineering records.
