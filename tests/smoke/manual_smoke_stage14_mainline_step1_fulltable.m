function out = manual_smoke_stage14_mainline_step1_fulltable(cfg, overrides)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP1_FULLTABLE
% Stage14.1 full-table smoke following the Stage05-style raw search idea.
%
% Purpose:
%   - keep fixed h, i, F
%   - scan a full P x T design table
%   - scan RAAN_rel outside the design table
%   - generate a raw Stage14 grid that can be reused by step2-step5
%
% Default setting:
%   h = 1000 km
%   i = 40 deg
%   F = stage05 F_fixed
%   P_grid = [4 6 8 10 12]
%   T_grid = [4 6 8 10 12]
%   RAAN_rel = 0:30:330
%
% Notes:
%   - this is the Stage05-style mainline input source
%   - unlike step1b, this does NOT constrain Ns in advance
%   - Ns-envelope remains a postprocessing layer in step3/step4/step5

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

    % Full-table search in Stage05 style
    ov.P_grid = [4 6 8 10 12];
    ov.T_grid = [4 6 8 10 12];
    ov.PT_pairs = [];

    % Relative orientation scan
    ov.RAAN_scan_deg = 0:30:330;

    % Smoke-scale execution
    ov.case_limit = 3;
    ov.use_early_stop = false;
    ov.hard_case_first = true;
    ov.progress_every = 10;

    ov.save_cache = true;
    ov.save_table = true;
    ov.make_plot = false;

    fn = fieldnames(overrides);
    for k = 1:numel(fn)
        ov.(fn{k}) = overrides.(fn{k});
    end

    out = stage14_scan_openD_raan_grid(cfg, ov);

    fprintf('\n=== Stage14.1 mainline full-table smoke summary ===\n');
    fprintf('grid rows       : %d\n', height(out.grid));
    fprintf('best pass_ratio : %.6f\n', max(out.grid.pass_ratio, [], 'omitnan'));
    fprintf('best D_G_min    : %.6f\n', max(out.grid.D_G_min, [], 'omitnan'));
    fprintf('unique Ns       : ');
    disp(unique(out.grid.Ns).')
    fprintf('unique P        : ');
    disp(unique(out.grid.P).')
    fprintf('unique T        : ');
    disp(unique(out.grid.T).')
    fprintf('table file      : %s\n', out.files.table_file);
    fprintf('cache file      : %s\n', out.files.cache_file);
    fprintf('log file        : %s\n\n', out.files.log_file);

    disp(out.grid(:, {'i_deg','P','T','F','RAAN_deg','Ns','D_G_min','D_G_mean','pass_ratio','feasible_flag'}));
end
