function out = manual_smoke_stage14_mainline_step2(cfg, opts)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP2
% Minimal smoke test for Stage14.2 first step:
%   fixed-design RAAN profiles from latest Stage14.1 raw grid.
%
% Default target design matches Stage14.1 step1 smoke:
%   h=1000, i=40, P=8, T=6, F=1

    if nargin < 1 || isempty(cfg)
        evalc('startup();');
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    local = struct();
    local.h_km = 1000;
    local.i_deg = 40;
    local.P = 8;
    local.T = 6;
    local.F = cfg.stage05.F_fixed;
    local.visible = "on";
    local.save_fig = true;
    local.save_table = true;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    out = stage14_plot_raan_profiles(cfg, local);

    fprintf('\n=== Stage14.2 step1 smoke summary ===\n');
    fprintf('rows            : %d\n', height(out.profile_table));
    fprintf('D_G_min span    : %.6f\n', out.summary.D_G_min_span);
    fprintf('pass_ratio span : %.6f\n', out.summary.pass_ratio_span);
    fprintf('DG plot         : %s\n', out.files.DG_min_png);
    fprintf('pass plot       : %s\n', out.files.pass_ratio_png);
    fprintf('table file      : %s\n\n', out.files.table_file);

    disp(out.profile_table(:, {'i_deg','P','T','F','RAAN_deg','Ns','D_G_min','D_G_mean','pass_ratio','feasible_flag'}));
end
