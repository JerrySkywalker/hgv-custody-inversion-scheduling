function out = manual_smoke_stage14_mainline_step7(cfg, opts)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP7
% Mainline A multi-inclination comparison smoke:
%   1) rebuild full-table raw grid with multiple i values
%   2) produce multi-i vs Ns comparison plots
%
% Default:
%   h = 1000 km
%   i_list = [30 40 50 60 70 80 90]
%   F = stage05.F_fixed
%
% IMPORTANT:
%   This mainline comparison now uses the full nominal-family policy
%   aligned with Stage05:
%       case_limit = inf
%       use_early_stop = false

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    local = struct();
    local.h_km = 1000;
    local.i_list = [30 40 50 60 70 80 90];
    local.F = cfg.stage05.F_fixed;
    local.visible = "on";
    local.save_fig = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    % Step 1: rebuild Stage14.1 full-table raw grid with multiple inclination values
    out_raw = manual_smoke_stage14_mainline_step1_fulltable(cfg, struct( ...
        'h_fixed_km', local.h_km, ...
        'i_grid_deg', local.i_list, ...
        'F_fixed', local.F, ...
        'P_grid', [4 6 8 10 12], ...
        'T_grid', [4 6 8 10 12], ...
        'RAAN_scan_deg', 0:30:330, ...
        'case_limit', inf, ...
        'use_early_stop', false, ...
        'hard_case_first', true, ...
        'require_pass_ratio', 1.0, ...
        'require_D_G_min', 1.0, ...
        'progress_every', 25, ...
        'save_cache', true, ...
        'save_table', true, ...
        'make_plot', false));

    % Step 2: build comparison plots from the latest stage14 cache
    out_cmp = stage14_plot_multi_i_ns_stats(cfg, struct( ...
        'h_km', local.h_km, ...
        'i_list', local.i_list, ...
        'F', local.F, ...
        'visible', local.visible, ...
        'save_fig', local.save_fig, ...
        'quiet', true));

    out = struct();
    out.raw = out_raw;
    out.summary_table_all = out_cmp.summary_table_all;
    out.files = out_cmp.files;

    fprintf('\n=== Stage14 mainline A step7 smoke summary ===\n');
    fprintf('i list            : ');
    disp(local.i_list);
    fprintf('raw grid rows     : %d\n', height(out_raw.grid));
    fprintf('DG mean plot      : %s\n', out_cmp.files.DG_mean_png);
    fprintf('DG min plot       : %s\n', out_cmp.files.DG_min_png);
    fprintf('DG span plot      : %s\n', out_cmp.files.DG_span_png);
    fprintf('pass mean plot    : %s\n', out_cmp.files.pass_mean_png);
    fprintf('pass min plot     : %s\n', out_cmp.files.pass_min_png);
    fprintf('pass span plot    : %s\n\n', out_cmp.files.pass_span_png);

    disp(out.summary_table_all);
end
