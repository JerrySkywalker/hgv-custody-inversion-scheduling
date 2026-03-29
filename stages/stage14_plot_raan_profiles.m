function out = stage14_plot_raan_profiles(cfg, opts)
%STAGE14_PLOT_RAAN_PROFILES
% Stage14.2 first step:
%   extract fixed-design RAAN profiles from latest Stage14.1 raw grid and
%   generate:
%     - D_G_min vs RAAN
%     - pass_ratio vs RAAN
%
% Current scope:
%   - one fixed design at a time
%   - no Ns-envelope yet
%   - no RAAN aggregated statistics yet

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    cfg.project_stage = 'stage14_plot_raan_profiles';
    cfg = configure_stage_output_paths(cfg);

    local = struct();
    local.h_km = NaN;
    local.i_deg = NaN;
    local.P = NaN;
    local.T = NaN;
    local.F = NaN;
    local.visible = "on";
    local.save_fig = true;
    local.save_table = true;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    [scan_out, scan_file] = local_load_latest_stage14_scan(cfg); %#ok<ASGLU>
    grid = scan_out.grid;

    assert(ismember('RAAN_deg', grid.Properties.VariableNames), 'Invalid Stage14 grid: missing RAAN_deg.');
    assert(ismember('D_G_min', grid.Properties.VariableNames), 'Invalid Stage14 grid: missing D_G_min.');
    assert(ismember('pass_ratio', grid.Properties.VariableNames), 'Invalid Stage14 grid: missing pass_ratio.');

    design_filter = true(height(grid),1);

    if ~isnan(local.h_km), design_filter = design_filter & (grid.h_km == local.h_km); end
    if ~isnan(local.i_deg), design_filter = design_filter & (grid.i_deg == local.i_deg); end
    if ~isnan(local.P), design_filter = design_filter & (grid.P == local.P); end
    if ~isnan(local.T), design_filter = design_filter & (grid.T == local.T); end
    if ~isnan(local.F), design_filter = design_filter & (grid.F == local.F); end

    profile_table = grid(design_filter, :);
    assert(height(profile_table) > 0, 'No Stage14 rows match the requested fixed design.');

    % Sanity: fixed-design profile should only vary in RAAN
    assert(numel(unique(profile_table.h_km)) == 1, 'Filtered profile has multiple h_km.');
    assert(numel(unique(profile_table.i_deg)) == 1, 'Filtered profile has multiple i_deg.');
    assert(numel(unique(profile_table.P)) == 1, 'Filtered profile has multiple P.');
    assert(numel(unique(profile_table.T)) == 1, 'Filtered profile has multiple T.');
    assert(numel(unique(profile_table.F)) == 1, 'Filtered profile has multiple F.');

    profile_table = sortrows(profile_table, 'RAAN_deg');

    tag = sprintf('h%d_i%.0f_P%d_T%d_F%d', ...
        round(profile_table.h_km(1)), ...
        profile_table.i_deg(1), ...
        profile_table.P(1), ...
        profile_table.T(1), ...
        profile_table.F(1));

    files = plot_stage14_raan_profiles(profile_table, cfg, ...
        'visible', local.visible, ...
        'save_fig', local.save_fig, ...
        'tag', tag);

    files.table_file = '';
    if local.save_table
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        files.table_file = fullfile(cfg.paths.tables, sprintf('stage14_raan_profile_%s_%s.csv', tag, timestamp));
        writetable(profile_table, files.table_file);
    end

    summary = struct();
    summary.scan_file = scan_file;
    summary.n_rows = height(profile_table);
    summary.h_km = profile_table.h_km(1);
    summary.i_deg = profile_table.i_deg(1);
    summary.P = profile_table.P(1);
    summary.T = profile_table.T(1);
    summary.F = profile_table.F(1);
    summary.Ns = profile_table.P(1) * profile_table.T(1);
    summary.D_G_min_min = min(profile_table.D_G_min, [], 'omitnan');
    summary.D_G_min_max = max(profile_table.D_G_min, [], 'omitnan');
    summary.D_G_min_span = summary.D_G_min_max - summary.D_G_min_min;
    summary.pass_ratio_min = min(profile_table.pass_ratio, [], 'omitnan');
    summary.pass_ratio_max = max(profile_table.pass_ratio, [], 'omitnan');
    summary.pass_ratio_span = summary.pass_ratio_max - summary.pass_ratio_min;

    out = struct();
    out.profile_table = profile_table;
    out.summary = summary;
    out.files = files;

    fprintf('\n=== Stage14.2 fixed-design RAAN profile ===\n');
    fprintf('scan file        : %s\n', summary.scan_file);
    fprintf('design           : h=%g, i=%g, P=%d, T=%d, F=%d, Ns=%d\n', ...
        summary.h_km, summary.i_deg, summary.P, summary.T, summary.F, summary.Ns);
    fprintf('rows             : %d\n', summary.n_rows);
    fprintf('D_G_min span     : %.6f\n', summary.D_G_min_span);
    fprintf('pass_ratio span  : %.6f\n', summary.pass_ratio_span);
    fprintf('DG plot          : %s\n', files.DG_min_png);
    fprintf('pass plot        : %s\n', files.pass_ratio_png);
    fprintf('table file       : %s\n\n', files.table_file);
end

function [scan_out, scan_file] = local_load_latest_stage14_scan(cfg)
    listing = find_stage_cache_files(cfg.paths.cache, 'stage14_scan_openD_raan_grid_*.mat');
    assert(~isempty(listing), 'No Stage14.1 cache found. Please run stage14_scan_openD_raan_grid first.');

    [~, idx] = max([listing.datenum]);
    scan_file = fullfile(listing(idx).folder, listing(idx).name);

    S = load(scan_file);
    assert(isfield(S, 'out') && isfield(S.out, 'grid'), 'Invalid Stage14.1 cache: missing out.grid.');

    scan_out = S.out;
end
