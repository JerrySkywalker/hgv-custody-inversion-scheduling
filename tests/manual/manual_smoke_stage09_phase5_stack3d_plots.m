function out = manual_smoke_stage09_phase5_stack3d_plots(base, varargin)
%MANUAL_SMOKE_STAGE09_PHASE5_STACK3D_PLOTS
% Use precomputed full-height base only, then export 4 metric-specific
% 3D stacked-over-h plots without rerunning search.
%
% Default behavior:
%   reset_plot3d_override = true
% which removes base.cfg.stage09.plot3d_stack before plotting, so that
% frozen code defaults are used.
%
% Optional name-value:
%   'reset_plot3d_override', true/false

    ip = inputParser;
    ip.addRequired('base', @(x) isstruct(x));
    ip.addParameter('reset_plot3d_override', true, @(x) islogical(x) || isnumeric(x));
    ip.parse(base, varargin{:});

    reset_plot3d_override = logical(ip.Results.reset_plot3d_override);

    out = struct();
    out.base_in = base;
    out.reset_plot3d_override = reset_plot3d_override;
    out.override_removed = false;

    fprintf('\n');
    fprintf('================ Phase5 Stack3D Plot Smoke ================\n');
    fprintf('Using precomputed full-height base only. No search rerun.\n');
    fprintf('Export 4 metric-specific 3D stacked-over-h plots.\n');
    fprintf('===========================================================\n\n');

    base_local = base;

    if reset_plot3d_override ...
            && isfield(base_local, 'cfg') && isstruct(base_local.cfg) ...
            && isfield(base_local.cfg, 'stage09') && isstruct(base_local.cfg.stage09) ...
            && isfield(base_local.cfg.stage09, 'plot3d_stack')
        base_local.cfg.stage09 = rmfield(base_local.cfg.stage09, 'plot3d_stack');
        out.override_removed = true;
        fprintf('[PHASE5] Removed base.cfg.stage09.plot3d_stack override. Using frozen defaults.\n');
    else
        if reset_plot3d_override
            fprintf('[PHASE5] No plot3d_stack override found. Using frozen defaults.\n');
        else
            fprintf('[PHASE5] Preserving base.cfg.stage09.plot3d_stack override.\n');
        end
    end

    out.base_used = base_local;

    out.joint = plot_stage09_metric_stack3d_over_h(base_local, 'joint', 'phase5_stack3d');
    out.DG    = plot_stage09_metric_stack3d_over_h(base_local, 'DG',    'phase5_stack3d');
    out.DA    = plot_stage09_metric_stack3d_over_h(base_local, 'DA',    'phase5_stack3d');
    out.DT    = plot_stage09_metric_stack3d_over_h(base_local, 'DT',    'phase5_stack3d');

    fprintf('\n');
    fprintf('================ Phase5 Stack3D Summary ================\n');
    fprintf('override removed  : %d\n', out.override_removed);
    fprintf('joint figure index : %s\n', out.joint.files.figure_index_csv);
    fprintf('DG    figure index : %s\n', out.DG.files.figure_index_csv);
    fprintf('DA    figure index : %s\n', out.DA.files.figure_index_csv);
    fprintf('DT    figure index : %s\n', out.DT.files.figure_index_csv);
    fprintf('========================================================\n\n');
end
