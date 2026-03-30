function out = manual_smoke_stage09_phase3_bundle_replot(base)
%MANUAL_SMOKE_STAGE09_PHASE3_BUNDLE_REPLOT
% Plot-only smoke for Phase3-B.
% A precomputed base is REQUIRED. This function must not rerun Stage09 search.

    if nargin < 1 || isempty(base)
        error('manual_smoke_stage09_phase3_bundle_replot:MissingBase', ...
            ['A precomputed base struct is required.' newline ...
             'Run: base = manual_smoke_stage09_phase1_metric_views_cached();']);
    end

    out = struct();

    fprintf('\n');
    fprintf('================ Phase3-B Bundle Replot Smoke ================\n');
    fprintf('Using precomputed base only. No search will be rerun.\n');
    fprintf('Step 1: export DG / DA / DT / joint packs in one bundle\n');
    fprintf('===============================================================\n');
    fprintf('\n');

    bundle = plot_stage09_bundle_all_packs(base, 'phase3_bundle');

    out.base = base;
    out.bundle = bundle;
    out.cfg = local_pick_cfg(base);

    fprintf('\n');
    fprintf('================ Phase3-B Bundle Summary ================\n');
    fprintf('Pack index CSV      : %s\n', bundle.files.pack_index_csv);
    fprintf('Master figure CSV   : %s\n', bundle.files.master_index_csv);
    fprintf('=========================================================\n');
    fprintf('\n');
end


function cfg = local_pick_cfg(base)

    if isfield(base, 'cfg') && isstruct(base.cfg)
        cfg = base.cfg;
        return;
    end

    if isfield(base, 's5') && isstruct(base.s5) && isfield(base.s5, 'cfg') && isstruct(base.s5.cfg)
        cfg = base.s5.cfg;
        return;
    end

    if isfield(base, 's4') && isstruct(base.s4) && isfield(base.s4, 'cfg') && isstruct(base.s4.cfg)
        cfg = base.s4.cfg;
        return;
    end

    if isfield(base, 's1') && isstruct(base.s1) && isfield(base.s1, 'cfg') && isstruct(base.s1.cfg)
        cfg = base.s1.cfg;
        return;
    end

    error('manual_smoke_stage09_phase3_bundle_replot:MissingCfg', ...
        'Unable to locate cfg from Phase1-B base.');
end
