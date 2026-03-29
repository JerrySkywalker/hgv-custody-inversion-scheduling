function out = stage14_joint_phase_orientation(cfg, opts)
%STAGE14_JOINT_PHASE_ORIENTATION
% Official Stage14.4 entry for joint phase-orientation sensitivity.
%
% Current architecture:
%   - raw grid      : frozen legacy raw grid logic
%   - postprocess   : official Stage14 postprocess layer
%   - analysis      : official reusable Stage14 analysis interface
%   - plotting      : official Stage14 plotting layer
%   - formal export : official Stage14 formal package layer
%
% Supported scope_name:
%   - A1
%   - A2

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    local = struct();
    local.scope_name = "A1";

    local.h_fixed_km = [];
    local.i_deg = [];
    local.P = [];
    local.T = [];
    local.F_values = [];
    local.RAAN_values = [];

    local.case_limit = inf;
    local.use_early_stop = false;
    local.hard_case_first = true;
    local.require_pass_ratio = 1.0;
    local.require_D_G_min = 1.0;

    local.save_fig = true;
    local.save_table = true;
    local.visible = 'on';

    local.do_postprocess = true;
    local.do_analysis = true;
    local.do_plot = true;
    local.do_formal_package = true;

    local.plot_visible = 'on';
    local.plot_timestamp = "";
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    profile = stage14_joint_phase_orientation_scope_profile(local.scope_name);

    if isempty(local.h_fixed_km),  local.h_fixed_km   = profile.h_fixed_km; end
    if isempty(local.i_deg),       local.i_deg        = profile.i_deg; end
    if isempty(local.P),           local.P            = profile.P; end
    if isempty(local.T),           local.T            = profile.T; end
    if isempty(local.RAAN_values), local.RAAN_values  = profile.RAAN_values; end
    local.scope_name = profile.scope_name;

    if isempty(local.F_values)
        local.F_values = 0:(local.P - 1);
    end
    if strlength(string(local.plot_timestamp)) == 0
        local.plot_timestamp = string(datestr(now, 'yyyymmdd_HHMMSS'));
    end

    required_funcs = { ...
        'manual_smoke_stage14_F_RAAN_grid_A1_legacy_prepivot_20260329', ...
        'stage14_postprocess_joint_phase_orientation', ...
        'stage14_analyze_joint_phase_orientation', ...
        'stage14_plot_joint_phase_orientation', ...
        'stage14_formal_package_joint_phase_orientation', ...
        'stage14_joint_phase_orientation_scope_profile' ...
    };
    for k = 1:numel(required_funcs)
        assert(exist(required_funcs{k}, 'file') == 2, ...
            'stage14_joint_phase_orientation:MissingDependency', ...
            'Required helper not found: %s', required_funcs{k});
    end

    if ~local.quiet
        fprintf('[stage14] === Stage14.4 joint phase-orientation sensitivity (%s) ===\n', char(local.scope_name));
        fprintf('[stage14] h = %.0f km, i = %.0f deg, P = %d, T = %d, Ns = %d\n', ...
            local.h_fixed_km, local.i_deg, local.P, local.T, local.P * local.T);
        fprintf('[stage14] F_values = %s\n', local_format_values(local.F_values));
        fprintf('[stage14] RAAN_values = %s\n', local_format_values(local.RAAN_values));
        fprintf('[stage14] pipeline = raw:%d | post:%d | analysis:%d | plot:%d | formal:%d\n', ...
            true, local.do_postprocess, local.do_analysis, local.do_plot, local.do_formal_package);
    end

    grid_visible = local.visible;
    grid_save_fig = local.save_fig;
    if local.do_plot
        grid_visible = 'off';
        grid_save_fig = false;
    end

    grid_overrides = struct( ...
        'h_fixed_km', local.h_fixed_km, ...
        'i_deg', local.i_deg, ...
        'P', local.P, ...
        'T', local.T, ...
        'F_values', local.F_values, ...
        'RAAN_values', local.RAAN_values, ...
        'case_limit', local.case_limit, ...
        'use_early_stop', local.use_early_stop, ...
        'hard_case_first', local.hard_case_first, ...
        'require_pass_ratio', local.require_pass_ratio, ...
        'require_D_G_min', local.require_D_G_min, ...
        'save_fig', grid_save_fig, ...
        'visible', grid_visible);

    out = struct();
    out.stage = 'stage14_joint_phase_orientation';
    out.scope = char(local.scope_name);
    out.options = local;

    % ------------------------------------------------------------
    % Raw grid
    % ------------------------------------------------------------
    out.grid = manual_smoke_stage14_F_RAAN_grid_A1_legacy_prepivot_20260329(cfg, grid_overrides);

    % ------------------------------------------------------------
    % Legacy-compatible postprocess output for current formal chain
    % ------------------------------------------------------------
    if local.do_postprocess
        out.post = stage14_postprocess_joint_phase_orientation( ...
            out.grid.summary_table, ...
            struct( ...
                'scope_name', local.scope_name, ...
                'save_table', false));
    else
        out.post = [];
    end

    % ------------------------------------------------------------
    % Official reusable analysis interface
    % ------------------------------------------------------------
    if local.do_analysis
        out.analysis = stage14_analyze_joint_phase_orientation( ...
            out.grid.summary_table, ...
            struct( ...
                'scope_name', local.scope_name, ...
                'quiet', local.quiet));
    else
        out.analysis = [];
    end

    % ------------------------------------------------------------
    % Official plotting layer
    % ------------------------------------------------------------
    if local.do_plot
        assert(~isempty(out.analysis), ...
            'stage14_joint_phase_orientation:AnalysisRequired', ...
            'Plotting requires analysis output.');

        out.plot = stage14_plot_joint_phase_orientation( ...
            out.grid.summary_table, ...
            out.analysis, ...
            cfg, ...
            struct( ...
                'scope_name', local.scope_name, ...
                'visible', local.plot_visible, ...
                'save_fig', local.save_fig, ...
                'timestamp', local.plot_timestamp, ...
                'quiet', local.quiet));
    else
        out.plot = [];
    end

    % ------------------------------------------------------------
    % Formal package
    % ------------------------------------------------------------
    if local.do_formal_package
        assert(~isempty(out.post), ...
            'stage14_joint_phase_orientation:PostprocessRequired', ...
            'Formal package requires postprocess output.');

        out.formal = stage14_formal_package_joint_phase_orientation( ...
            out.grid, out.post, cfg, struct( ...
                'scope_name', local.scope_name, ...
                'save_table', local.save_table, ...
                'save_markdown', true, ...
                'timestamp', local.plot_timestamp, ...
                'quiet', local.quiet));
    else
        out.formal = [];
    end

    if ~local.quiet
        fprintf('[stage14] Stage14.4 joint phase-orientation sensitivity completed (%s).\n', char(local.scope_name));
        if isstruct(out.plot) && isfield(out.plot, 'out_dir')
            fprintf('[stage14] plot dir = %s\n', out.plot.out_dir);
        end
        if isstruct(out.formal) && isfield(out.formal, 'out_dir')
            fprintf('[stage14] formal dir = %s\n', out.formal.out_dir);
        end
    end
end

function s = local_format_values(values)
    values = values(:)';
    if isempty(values)
        s = '[]';
        return;
    end
    if numel(values) == 1
        s = sprintf('%g', values(1));
        return;
    end
    diffs = diff(values);
    if all(abs(diffs - diffs(1)) < 1e-12)
        s = sprintf('%g:%g:%g', values(1), diffs(1), values(end));
    else
        s = ['[' strjoin(arrayfun(@(v) sprintf('%g', v), values, 'UniformOutput', false), ', ') ']'];
    end
end
