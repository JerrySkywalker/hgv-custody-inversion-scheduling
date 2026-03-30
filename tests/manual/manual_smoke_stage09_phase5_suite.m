function out = manual_smoke_stage09_phase5_suite()
%MANUAL_SMOKE_STAGE09_PHASE5_SUITE
% New Phase5 suite:
%   1) Build full-height base
%   2) Export 4 metric-specific stack3d-over-h plots
%
% This suite is intentionally separated from closure_heatmaps:
%   - planar closure_heatmaps remains the old version
%   - Phase5 is now metric-wise 3D stack over h

    startup('force', true);
    rehash;

    fprintf('\n');
    fprintf('================ Stage09 Phase5 Suite ================\n');
    fprintf('Step 1: build full-height base\n');
    fprintf('Step 2: export joint/DG/DA/DT stack3d-over-h plots\n');
    fprintf('======================================================\n\n');

    out = struct();

    out.base = manual_smoke_stage09_phase5_build_fullheight_base();
    out.stack3d = manual_smoke_stage09_phase5_stack3d_plots(out.base);

    fprintf('\n');
    fprintf('================ Stage09 Phase5 Suite Summary ================\n');
    fprintf('joint figure index : %s\n', out.stack3d.joint.files.figure_index_csv);
    fprintf('DG    figure index : %s\n', out.stack3d.DG.files.figure_index_csv);
    fprintf('DA    figure index : %s\n', out.stack3d.DA.files.figure_index_csv);
    fprintf('DT    figure index : %s\n', out.stack3d.DT.files.figure_index_csv);
    fprintf('=============================================================\n\n');
end
