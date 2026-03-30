function out = manual_smoke_stage09_phase5_suite()
%MANUAL_SMOKE_STAGE09_PHASE5_SUITE
% Phase5 suite:
%   1) Reuse cached Phase1 base
%   2) Export 3D stacked closure heatmap figure
%   3) Verify Phase4-C guarded feature
%
% This suite must not rerun search if the cached base already exists.

    startup('force', true);
    rehash;

    fprintf('\n');
    fprintf('================ Stage09 Phase5 Suite ================\n');
    fprintf('Step 1: reuse/build cached Phase1 base\n');
    fprintf('Step 2: export Phase5 3D stacked heatmap\n');
    fprintf('Step 3: verify Phase4-C guarded feature\n');
    fprintf('======================================================\n\n');

    out = struct();

    base = manual_smoke_stage09_phase1_metric_views_cached();
    out.base = base;

    out.phase5Stack3D = plot_stage09_phase5_stacked_heatmaps_3d(base, 'phase5_stack3d');

    out.phase4C_guard = struct();
    out.phase4C_guard.triggered = false;
    out.phase4C_guard.identifier = "";
    out.phase4C_guard.message = "";

    try
        tmp = manual_smoke_stage09_phase4_closure_heatmaps_hi(base); %#ok<NASGU>
        fprintf('[WARN] Phase4-C guard did not trigger.\n');
    catch ME
        out.phase4C_guard.triggered = strcmp(ME.identifier, ...
            'plot_stage09_closure_heatmaps_hi:InsufficientHLevels');
        out.phase4C_guard.identifier = string(ME.identifier);
        out.phase4C_guard.message = string(ME.message);

        fprintf('[EXPECTED GUARD] %s\n', ME.identifier);
        fprintf('[EXPECTED GUARD] %s\n', ME.message);
    end

    fprintf('\n');
    fprintf('================ Stage09 Phase5 Suite Summary ================\n');
    fprintf('Phase5 3D figure index : %s\n', out.phase5Stack3D.files.figure_index_csv);
    fprintf('Phase4-C guard ok      : %d\n', out.phase4C_guard.triggered);
    fprintf('=============================================================\n\n');
end
