# MB Cache Policy Final Repair Round

## This round is intentionally all-fresh
- semantic reuse: disabled
- plot reuse: disabled
- export reuse: disabled
- rebuild-all: enabled

## Required switches
- `cfg.runtime.force_fresh = true`
- `cfg.runtime.regenerate_all_cache = true`
- `cfg.runtime.regenerate_all_export = true`
- `cfg.cache.force_fresh = true`
- `cfg.cache.reuse_semantic = false`
- `cfg.cache.reuse_plot = false`
- `cfg.cache.rebuild_all = true`

## Manifest expectations
- `fresh_recompute_manifest.csv` must record every semantic artifact as fresh unless it is a static seed input.
- current accepted static reuse is limited to immutable setup inputs such as `static_stage01_seed_reused_only`.
- history/domain-related phasecurve and surface caches must not be reused in this round.

## Why this policy exists
- it prevents stale tail-only passratio tables from surviving into `historyFull`
- it prevents old local-domain heatmap surfaces from being mislabeled as `globalSkeleton`
- it forces the 500/750/1000 km bundle to be regenerated from one consistent runtime profile
