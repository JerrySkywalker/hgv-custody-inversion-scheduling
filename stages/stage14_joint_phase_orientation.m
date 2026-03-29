function out = stage14_joint_phase_orientation(cfg, opts)
%STAGE14_JOINT_PHASE_ORIENTATION
% Official Stage14.4 entry for joint phase-orientation sensitivity.
%
% This function does NOT rewrite legacy A1 logic.
% It formally wraps the frozen pre-pivot assets into a stable Stage14.4 stage:
%   1) joint (F, RAAN_rel) grid
%   2) postprocess
%   3) formal package
%
% Current scope:
%   - A1 only: h=1000 km, i=40 deg, P=8, T=6
%
% Inputs:
%   cfg  : project config
%   opts : struct overrides
%
% Outputs:
%   out.grid
%   out.post
%   out.formal

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
        'manual_smoke_stage14_F_RAAN_postprocess_A1_legacy_prepivot_20260329', ...
        'manual_smoke_stage14_A1_formal_package_legacy_prepivot_20260329' ...
    };
    for k = 1:numel(required_funcs)
        assert(exist(required_funcs{k}, 'file') == 2, ...
            'stage14_joint_phase_orientation:MissingDependency', ...
            'Required legacy helper not found: %s', required_funcs{k});
    end

    if ~local.quiet
        fprintf('[stage14] === Stage14.4 joint phase-orientation sensitivity (A1) ===\n');
        fprintf('[stage14] h = %.0f km, i = %.0f deg, P = %d, T = %d\n', ...
            local.h_fixed_km, local.i_deg, local.P, local.T);
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

    out.grid = manual_smoke_stage14_F_RAAN_grid_A1_legacy_prepivot_20260329(cfg, grid_overrides);

    if local.do_postprocess
        post_overrides = struct( ...
            'save_fig', local.save_fig, ...
            'visible', local.visible);
        out.post = manual_smoke_stage14_F_RAAN_postprocess_A1_legacy_prepivot_20260329( ...
            out.grid, cfg, post_overrides);
    else
        out.post = [];
    end

    if local.do_formal_package
        assert(~isempty(out.post), ...
            'stage14_joint_phase_orientation:PostprocessRequired', ...
            'Formal package requires postprocess output.');
        formal_overrides = struct();
        out.formal = manual_smoke_stage14_A1_formal_package_legacy_prepivot_20260329( ...
            out.grid, out.post, cfg, formal_overrides);
    else
        out.formal = [];
    end

    if ~local.quiet
        fprintf('[stage14] Stage14.4 joint phase-orientation sensitivity completed.\n');
    end
end
