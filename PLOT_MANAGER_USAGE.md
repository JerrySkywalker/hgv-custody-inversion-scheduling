# Plot Manager Usage

## Runtime Fields

Global plotting behavior is controlled by `cfg.runtime.plotting`.

Common fields:

- `mode = 'headless' | 'visible'`
- `close_after_save`
- `reuse_figures`
- `export_dpi`
- `renderer`

Milestone defaults are initialized in `milestone_common_defaults`.

## Managed Figure Flow

Preferred flow:

1. create figures with `create_managed_figure`
2. export with `finalize_managed_figure_export`
3. close figures through runtime policy or `close_figure_if_headless`

This keeps headless and visible behavior consistent.

## Headless Mode

`headless` means:

- figures are created off-screen
- PNG/PDF/FIG export still works
- figures are closed after export when configured

This mode is intended for batch MB runs, milestone runners, and stage smoke tests.

## Visible Mode

`visible` means figures can open for interactive debugging while preserving the same export helpers.

## Entry Points

Headless plotting is intended to be driven from run-layer entry points such as:

- `run_milestone_B_semantic_compare`
- `run_stageXX_*`
- `run_all_stages`

The goal is to avoid scattering raw `figure('Visible','off')` logic across analysis code.
