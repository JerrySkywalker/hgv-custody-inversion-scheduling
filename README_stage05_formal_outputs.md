# Stage05 Formal Outputs

## 1. Main suite artifact root

Default artifact root pattern:

- `outputs/experiments/chapter4/stage05_formal_suite/<run_name>/`

## 2. Core outputs

### 2.1 Manifest
- `manifest/manifest.mat`
- `manifest/manifest.txt`

### 2.2 Summary table
- `summary/summary_table.csv`
- `summary/summary_table.mat`

### 2.3 Formal figures
- `formal_figures/formal_figures_manifest.txt`
- `formal_figures/legacy_best_pass_by_Ns.png`
- `formal_figures/legacy_geometry_heatmap_i60.png`
- `formal_figures/opend_env_min_DG.png`
- `formal_figures/opend_env_min_pass_ratio.png`
- `formal_figures/closedd_env_min_joint_margin.png`
- `formal_figures/closedd_env_min_pass_ratio.png`

## 3. Branch-specific artifacts

### 3.1 Legacy reproduction
- `legacy_reproduction/`

### 3.2 OpenD manual-RAAN
- `opend_manual_raan/`

### 3.3 ClosedD manual-RAAN
- `closedd_manual_raan/`

## 4. Regression gates currently available

### 4.1 Validation
- `assert_stage05_validation_suite`
- `assert_stage05_plot_validation_suite`

### 4.2 Formal suite
- `assert_stage05_formal_suite_result`
- `assert_stage05_formal_suite`

## 5. Purpose

This folder structure is intended to separate:

- regression validation assets
- formal experiment assets
- paper-ready summary tables
- paper-ready figures
