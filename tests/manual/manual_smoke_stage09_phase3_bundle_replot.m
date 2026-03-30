function out = manual_smoke_stage09_phase3_bundle_replot(base)
%MANUAL_SMOKE_STAGE09_PHASE3_BUNDLE_REPLOT
% Plot-only smoke for Phase3-B. If a precomputed base is provided, no
% Stage09 search is rerun.

    if nargin < 1
        base = [];
    end

    out = struct();

    fprintf('\n');
    fprintf('================ Phase3-B Bundle Replot Smoke ================\n');
    fprintf('Step 1: obtain Phase1-B base (or reuse provided base)\n');
    fprintf('Step 2: export DG / DA / DT / joint packs in one bundle\n');
    fprintf('===============================================================\n');
    fprintf('\n');

    if isempty(base)
        fprintf('[PHASE3-B] No base provided. Building Phase1-B base once...\n');
        base = manual_smoke_stage09_phase1_metric_views();
    else
        fprintf('[PHASE3-B] Using precomputed base only. No search will be rerun.\n');
    end

    bundle = plot_stage09_bundle_all_packs(base, 'phase3_bundle');

    out.base = base;
    out.bundle = bundle;
    out.cfg = base.cfg;

    fprintf('\n');
    fprintf('================ Phase3-B Bundle Summary ================\n');
    fprintf('Pack index CSV      : %s\n', bundle.files.pack_index_csv);
    fprintf('Master figure CSV   : %s\n', bundle.files.master_index_csv);
    fprintf('=========================================================\n');
    fprintf('\n');
end
