# Phase 9 summary

## Goal
Sweep the custody window length T_w for methods:
- T
- C
- CK

and compare:
- q_worst_window
- phi_mean
- outage_ratio
- longest_outage_steps
- mean_rmse

## Official evaluation
- q_worst_window is the official worst-window metric
- q_worst_point is diagnostic only

## Scenes
- stress96
- ref128

## Full grid
- [10 20 30 40 60 80]

---

## Results summary

### Global trend
Across both scenes:
- q_worst_window decreases monotonically as T_w increases
- outage_ratio increases monotonically as T_w increases
- longest_outage_steps increases approximately as:
  4 -> 8 -> 13 -> 17 -> 26 -> 35
- mean_rmse is nearly invariant with respect to T_w

Interpretation:
- larger custody windows impose stricter worst-window evaluation
- longer windows expose and amplify persistent bad segments
- the main variation in Phase 9 occurs on the custody side, not the tracking side

---

## stress96

### T
- T_w=10: q_worst_window=0.481641, phi_mean=0.557076, outage_ratio=0.011236, longest_outage_steps=4, mean_rmse=0.911476
- T_w=20: q_worst_window=0.426186, phi_mean=0.554972, outage_ratio=0.016230, longest_outage_steps=8, mean_rmse=0.911476
- T_w=30: q_worst_window=0.342023, phi_mean=0.552871, outage_ratio=0.022472, longest_outage_steps=13, mean_rmse=0.911476
- T_w=40: q_worst_window=0.262500, phi_mean=0.550773, outage_ratio=0.027466, longest_outage_steps=17, mean_rmse=0.911476
- T_w=60: q_worst_window=0.175000, phi_mean=0.546590, outage_ratio=0.038702, longest_outage_steps=26, mean_rmse=0.911476
- T_w=80: q_worst_window=0.131250, phi_mean=0.542383, outage_ratio=0.048689, longest_outage_steps=35, mean_rmse=0.911476

### C
- T_w=10: q_worst_window=0.433439, phi_mean=0.527758, outage_ratio=0.007491, longest_outage_steps=4, mean_rmse=1.000400
- T_w=20: q_worst_window=0.376955, phi_mean=0.528834, outage_ratio=0.012484, longest_outage_steps=8, mean_rmse=1.000400
- T_w=30: q_worst_window=0.319709, phi_mean=0.529671, outage_ratio=0.018727, longest_outage_steps=13, mean_rmse=1.000400
- T_w=40: q_worst_window=0.261695, phi_mean=0.530262, outage_ratio=0.023720, longest_outage_steps=17, mean_rmse=1.000400
- T_w=60: q_worst_window=0.175000, phi_mean=0.530679, outage_ratio=0.034956, longest_outage_steps=26, mean_rmse=1.000400
- T_w=80: q_worst_window=0.131250, phi_mean=0.530053, outage_ratio=0.046192, longest_outage_steps=35, mean_rmse=1.000400

### CK
- T_w=10: q_worst_window=0.446109, phi_mean=0.534040, outage_ratio=0.017478, longest_outage_steps=6, mean_rmse=0.975082
- T_w=20: q_worst_window=0.426186, phi_mean=0.531738, outage_ratio=0.022472, longest_outage_steps=8, mean_rmse=0.974615
- T_w=30: q_worst_window=0.342023, phi_mean=0.529385, outage_ratio=0.028714, longest_outage_steps=13, mean_rmse=0.974615
- T_w=40: q_worst_window=0.262500, phi_mean=0.526668, outage_ratio=0.036205, longest_outage_steps=17, mean_rmse=0.974515
- T_w=60: q_worst_window=0.175000, phi_mean=0.522673, outage_ratio=0.047441, longest_outage_steps=26, mean_rmse=0.973060
- T_w=80: q_worst_window=0.131250, phi_mean=0.517478, outage_ratio=0.059925, longest_outage_steps=35, mean_rmse=0.972825

Interpretation:
- CK has visible q_worst_window advantage over C at short windows, especially T_w=20 and T_w=30
- as T_w increases, this advantage shrinks rapidly and essentially disappears by T_w >= 40
- CK keeps better RMSE than C, but pays with higher outage_ratio

---

## ref128

### T
- T_w=10: q_worst_window=0.530748, phi_mean=0.572504, outage_ratio=0.012484, longest_outage_steps=4, mean_rmse=0.911476
- T_w=20: q_worst_window=0.439412, phi_mean=0.570144, outage_ratio=0.017478, longest_outage_steps=8, mean_rmse=0.911476
- T_w=30: q_worst_window=0.345923, phi_mean=0.567809, outage_ratio=0.023720, longest_outage_steps=13, mean_rmse=0.911476
- T_w=40: q_worst_window=0.262500, phi_mean=0.565502, outage_ratio=0.028714, longest_outage_steps=17, mean_rmse=0.911476
- T_w=60: q_worst_window=0.175000, phi_mean=0.560971, outage_ratio=0.039950, longest_outage_steps=26, mean_rmse=0.911476
- T_w=80: q_worst_window=0.131250, phi_mean=0.556528, outage_ratio=0.051186, longest_outage_steps=35, mean_rmse=0.911476

### C
- T_w=10: q_worst_window=0.452098, phi_mean=0.525551, outage_ratio=0.008739, longest_outage_steps=4, mean_rmse=1.000400
- T_w=20: q_worst_window=0.398767, phi_mean=0.527832, outage_ratio=0.013733, longest_outage_steps=8, mean_rmse=1.000400
- T_w=30: q_worst_window=0.325929, phi_mean=0.529135, outage_ratio=0.019975, longest_outage_steps=13, mean_rmse=1.000400
- T_w=40: q_worst_window=0.262500, phi_mean=0.531293, outage_ratio=0.024969, longest_outage_steps=17, mean_rmse=1.000400
- T_w=60: q_worst_window=0.175000, phi_mean=0.535051, outage_ratio=0.036205, longest_outage_steps=26, mean_rmse=1.000400
- T_w=80: q_worst_window=0.131250, phi_mean=0.537886, outage_ratio=0.047441, longest_outage_steps=35, mean_rmse=1.000400

### CK
- T_w=10: q_worst_window=0.481669, phi_mean=0.559514, outage_ratio=0.016230, longest_outage_steps=4, mean_rmse=0.977900
- T_w=20: q_worst_window=0.434412, phi_mean=0.559872, outage_ratio=0.021223, longest_outage_steps=8, mean_rmse=0.977449
- T_w=30: q_worst_window=0.342590, phi_mean=0.558650, outage_ratio=0.026217, longest_outage_steps=13, mean_rmse=0.977386
- T_w=40: q_worst_window=0.260000, phi_mean=0.556870, outage_ratio=0.031211, longest_outage_steps=17, mean_rmse=0.977286
- T_w=60: q_worst_window=0.173333, phi_mean=0.551909, outage_ratio=0.041199, longest_outage_steps=26, mean_rmse=0.975780
- T_w=80: q_worst_window=0.130000, phi_mean=0.547411, outage_ratio=0.052434, longest_outage_steps=35, mean_rmse=0.975557

Interpretation:
- CK remains better than C on q_worst_window and phi_mean in short windows
- the advantage is strongest around T_w=20 and still visible at T_w=30
- for large windows, all three methods converge in q_worst_window while CK still keeps slightly better RMSE than C

---

## Main conclusion
Phase 9 shows that CK is not a uniform all-window winner.
Its main advantage is concentrated in short to medium-short windows.

More specifically:
- CK is most valuable when the mission emphasizes short-horizon worst-window custody
- as T_w increases, the local geometry-driven advantage is averaged out
- CK keeps better RMSE than C, but does not reduce fragmented outage events as effectively as C

## Recommended Chapter-5 presentation
- use q_worst_window vs T_w as a main figure
- use outage_ratio vs T_w as a companion figure
- use mean_rmse vs T_w as a supporting figure
- treat T_w = 20 as the primary representative operating point
- treat T_w = 30 as a secondary robustness check
