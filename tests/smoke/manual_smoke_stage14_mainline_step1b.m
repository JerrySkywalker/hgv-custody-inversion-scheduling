function out = manual_smoke_stage14_mainline_step1b(cfg, overrides)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP1B
% Expanded smoke test for Stage14.1 mainline.
%
% Purpose:
%   - keep fixed h, i, F
%   - expand to multiple (P,T) with the same Ns
%   - densify RAAN sampling
%   - provide a meaningful basis for Stage14.2 Ns-envelope curves
%
% Default design family:
%   h = 1000 km
%   i = 40 deg
%   F = stage05 F_fixed
%   Ns = 48 with explicit PT pairs:
%       (4,12), (6,8), (8,6), (12,4)
%   RAAN_rel = 0:30:330

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

    % Explicit PT pair list (fixed Ns = 48)
    ov.PT_pairs = [
        4 12
        6  8
        8  6
        12 4
    ];

    % Keep legacy fields empty to avoid accidental Cartesian-product usage
    ov.P_grid = [];
    ov.T_grid = [];

    ov.RAAN_scan_deg = 0:30:330;

    % Keep smoke-scale execution
    ov.case_limit = 3;
    ov.use_early_stop = false;
    ov.hard_case_first = true;
    ov.progress_every = 6;

    ov.save_cache = true;
    ov.save_table = true;
    ov.make_plot = false;

    fn = fieldnames(overrides);
    for k = 1:numel(fn)
        ov.(fn{k}) = overrides.(fn{k});
    end

    out = stage14_scan_openD_raan_grid(cfg, ov);

    fprintf('\n=== Stage14.1 mainline smoke step1b summary ===\n');
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
