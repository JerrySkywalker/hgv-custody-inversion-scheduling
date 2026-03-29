function out = manual_smoke_stage14_mainline_step1(cfg, overrides)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP1
% Minimal smoke test for the new Stage14.1 mainline.
%
% Scope:
%   - tiny grid only
%   - verify raw scan over (i,P,T,RAAN)
%   - verify csv/cache/log are generated
%   - verify RAAN=0 path is computable under new mainline naming

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    ov = struct();
    ov.h_fixed_km = 1000;
    ov.F_fixed = cfg.stage05.F_fixed;
    ov.i_grid_deg = 40;
    ov.P_grid = 8;
    ov.T_grid = 6;
    ov.RAAN_scan_deg = [0 90 180 270];
    ov.case_limit = 3;
    ov.use_early_stop = false;
    ov.hard_case_first = true;
    ov.progress_every = 1;
    ov.save_cache = true;
    ov.save_table = true;
    ov.make_plot = false;

    fn = fieldnames(overrides);
    for k = 1:numel(fn)
        ov.(fn{k}) = overrides.(fn{k});
    end

    out = stage14_scan_openD_raan_grid(cfg, ov);

    fprintf('\n=== Stage14.1 mainline smoke summary ===\n');
    fprintf('grid rows      : %d\n', height(out.grid));
    fprintf('best pass_ratio: %.6f\n', max(out.grid.pass_ratio, [], 'omitnan'));
    fprintf('best D_G_min   : %.6f\n', max(out.grid.D_G_min, [], 'omitnan'));
    fprintf('table file     : %s\n', out.files.table_file);
    fprintf('cache file     : %s\n', out.files.cache_file);
    fprintf('log file       : %s\n\n', out.files.log_file);

    disp(out.grid(:, {'i_deg','P','T','F','RAAN_deg','Ns','D_G_min','D_G_mean','pass_ratio','feasible_flag'}));
end
