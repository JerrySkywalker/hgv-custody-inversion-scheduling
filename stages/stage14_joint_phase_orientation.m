function out = stage14_joint_phase_orientation(cfg, opts)
%STAGE14_JOINT_PHASE_ORIENTATION
% Official Stage14.4 entry for joint phase-orientation sensitivity.
%
% Current architecture:
%   - raw grid      : frozen legacy A1 grid
%   - postprocess   : official Stage14 postprocess layer
%   - formal export : official Stage14 formal package layer
%
% Current scope:
%   - A1 only: h=1000 km, i=40 deg, P=8, T=6

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    local = struct();
    local.h_fixed_km = 1000;
    local.i_deg = 40;
    local.P = 8;
    local.T = 6;
    local.F_values = [];
    local.RAAN_values = 0:15:345;

    local.case_limit = inf;
    local.use_early_stop = false;
    local.hard_case_first = true;
    local.require_pass_ratio = 1.0;
    local.require_D_G_min = 1.0;

    local.save_fig = true;
    local.save_table = true;
    local.visible = 'on';

    local.do_postprocess = true;
    local.do_formal_package = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    if isempty(local.F_values)
        local.F_values = 0:(local.P - 1);
    end

    required_funcs = { ...
        'manual_smoke_stage14_F_RAAN_grid_A1_legacy_prepivot_20260329', ...
        'stage14_postprocess_joint_phase_orientation', ...
        'stage14_formal_package_joint_phase_orientation' ...
    };
    for k = 1:numel(required_funcs)
        assert(exist(required_funcs{k}, 'file') == 2, ...
            'stage14_joint_phase_orientation:MissingDependency', ...
            'Required helper not found: %s', required_funcs{k});
    end

    if ~local.quiet
        fprintf('[stage14] === Stage14.4 joint phase-orientation sensitivity (A1) ===\n');
        fprintf('[stage14] h = 1000 km, i = 40 deg, P = 8, T = 6\n');
        fprintf('[stage14] F_values = ');
        disp(local.F_values);
        fprintf('[stage14] RAAN_values = ');
        disp(local.RAAN_values);
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
        'save_fig', local.save_fig, ...
        'visible', local.visible);

    out = struct();
    out.stage = 'stage14_joint_phase_orientation';
    out.scope = 'A1';
    out.options = local;

    % ------------------------------------------------------------
    % B1 raw grid: keep legacy A1 grid as frozen asset
    % ------------------------------------------------------------
    out.grid = manual_smoke_stage14_F_RAAN_grid_A1_legacy_prepivot_20260329(cfg, grid_overrides);

    % ------------------------------------------------------------
    % B2 / B2-dual postprocess: official Stage14 postprocess layer
    % ------------------------------------------------------------
    if local.do_postprocess
        out.post = stage14_postprocess_joint_phase_orientation( ...
            out.grid.summary_table, ...
            struct( ...
                'scope_name', "A1", ...
                'save_table', false));
    else
        out.post = [];
    end

    % ------------------------------------------------------------
    % Formal package: official Stage14 formal export layer
    % ------------------------------------------------------------
    if local.do_formal_package
        assert(~isempty(out.post), ...
            'stage14_joint_phase_orientation:PostprocessRequired', ...
            'Formal package requires postprocess output.');

        out.formal = stage14_formal_package_joint_phase_orientation( ...
            out.grid, out.post, cfg, struct( ...
                'scope_name', "A1", ...
                'save_table', local.save_table, ...
                'save_markdown', true, ...
                'quiet', local.quiet));
    else
        out.formal = [];
    end

    if ~local.quiet
        fprintf('[stage14] Stage14.4 joint phase-orientation sensitivity completed.\n');
    end
end
