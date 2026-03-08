# Milestone M1 baseline summary

Generated: 2026-03-08 09:38:00

## Key settings

- Protected disk radius: 1000.0 km
- Entry boundary radius: 3000.0 km
- Walker baseline: h=1000.0 km, i=70.0 deg, P=8, T=12, F=1
- Worst-window length: 60.0 s
- Margin threshold gamma_req: 1.000

## Stage02 trajectory-level observations

- Nominal, heading, and critical trajectory families were all generated successfully.
- Stage02 produced scenario plot, 2D trajectory plot, and 3D explanatory trajectory plot.

## Stage03 visibility-level observations

- Single-layer Walker baseline was connected to the Stage02 trajectory bank.
- Visibility and LOS geometry differences already appeared across nominal / heading / critical cases.

## Stage04 worst-window observations

- Family nominal: D_G_mean = 208.794, pass_ratio = 0.333333
- Family heading: D_G_mean = 79.9829, pass_ratio = 0.166667
- Family critical: D_G_mean = 0.0827905, pass_ratio = 0

## Interim conclusions

1. The single-layer Walker baseline is not uniformly feasible across the full scenario set.
2. Nominal scenarios only partially pass the threshold; heading expansion further reduces pass ratio.
3. Critical scenarios fail under the current threshold, showing strong worst-window fragility.
4. Worst-window spectrum is more discriminative than average visibility-type indicators.

## Next step

- Proceed to Stage05A: h-i slice scanning for single-layer baseline feasibility mapping.
