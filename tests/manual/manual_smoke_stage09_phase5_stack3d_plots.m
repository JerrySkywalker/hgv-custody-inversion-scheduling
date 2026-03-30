function out = manual_smoke_stage09_phase5_stack3d_plots(base)
%MANUAL_SMOKE_STAGE09_PHASE5_STACK3D_PLOTS
% Build 3D stacked-over-h plots for joint / DG / DA / DT from a full-height base.

    if nargin < 1 || isempty(base)
        error('manual_smoke_stage09_phase5_stack3d_plots:MissingBase', ...
            'A full-height base is required. Run manual_smoke_stage09_phase5_build_fullheight_base() first.');
    end

    fprintf('\n');
    fprintf('================ Phase5 Stack3D Plot Smoke ================\n');
    fprintf('Using precomputed full-height base only. No search rerun.\n');
    fprintf('Export 4 metric-specific 3D stacked-over-h plots.\n');
    fprintf('===========================================================\n\n');

    out = struct();
    out.base = base;

    out.joint = plot_stage09_metric_stack3d_over_h(base, 'joint', 'phase5_stack3d');
    out.DG    = plot_stage09_metric_stack3d_over_h(base, 'DG',    'phase5_stack3d');
    out.DA    = plot_stage09_metric_stack3d_over_h(base, 'DA',    'phase5_stack3d');
    out.DT    = plot_stage09_metric_stack3d_over_h(base, 'DT',    'phase5_stack3d');

    fprintf('\n');
    fprintf('================ Phase5 Stack3D Summary ================\n');
    fprintf('joint figure index : %s\n', out.joint.files.figure_index_csv);
    fprintf('DG    figure index : %s\n', out.DG.files.figure_index_csv);
    fprintf('DA    figure index : %s\n', out.DA.files.figure_index_csv);
    fprintf('DT    figure index : %s\n', out.DT.files.figure_index_csv);
    fprintf('========================================================\n\n');
end
