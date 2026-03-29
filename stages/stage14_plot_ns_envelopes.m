function out = stage14_plot_ns_envelopes(cfg, opts)
%STAGE14_PLOT_NS_ENVELOPES
% Stage14.2 second step:
%   for fixed (h, i, Ns, F), take PT-envelope at each RAAN_rel and plot:
%     - max_PT D_G_min vs RAAN_rel
%     - max_PT pass_ratio vs RAAN_rel

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    cfg.project_stage = 'stage14_plot_ns_envelopes';
    cfg = configure_stage_output_paths(cfg);

    local = struct();
    local.h_km = NaN;
    local.i_deg = NaN;
    local.Ns = NaN;
    local.F = NaN;
    local.visible = "on";
    local.save_fig = true;
    local.save_table = true;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    [scan_out, scan_file] = local_load_latest_stage14_scan(cfg);
    grid = scan_out.grid;

    requiredVars = {'h_km','i_deg','P','T','F','RAAN_deg','Ns','D_G_min','pass_ratio'};
    for k = 1:numel(requiredVars)
        assert(ismember(requiredVars{k}, grid.Properties.VariableNames), ...
            'Invalid Stage14 grid: missing %s', requiredVars{k});
    end

    filter_mask = true(height(grid),1);
    if ~isnan(local.h_km), filter_mask = filter_mask & (grid.h_km == local.h_km); end
    if ~isnan(local.i_deg), filter_mask = filter_mask & (grid.i_deg == local.i_deg); end
    if ~isnan(local.Ns), filter_mask = filter_mask & (grid.Ns == local.Ns); end
    if ~isnan(local.F), filter_mask = filter_mask & (grid.F == local.F); end

    subgrid = grid(filter_mask, :);
    assert(height(subgrid) > 0, 'No Stage14 rows match the requested (h,i,Ns,F) filter.');

    assert(numel(unique(subgrid.h_km)) == 1, 'Filtered grid has multiple h_km.');
    assert(numel(unique(subgrid.i_deg)) == 1, 'Filtered grid has multiple i_deg.');
    assert(numel(unique(subgrid.Ns)) == 1, 'Filtered grid has multiple Ns.');
    assert(numel(unique(subgrid.F)) == 1, 'Filtered grid has multiple F.');

    RAAN_values = unique(subgrid.RAAN_deg);
    RAAN_values = sort(RAAN_values);

    rows = cell(0, 12);

    for ir = 1:numel(RAAN_values)
        raan = RAAN_values(ir);
        rows_r = subgrid(subgrid.RAAN_deg == raan, :);
        assert(height(rows_r) >= 1, 'Empty RAAN slice encountered.');

        [dg_best_val, idx_dg] = max(rows_r.D_G_min, [], 'omitnan');
        [pr_best_val, idx_pr] = max(rows_r.pass_ratio, [], 'omitnan');

        rows(end+1,:) = { ...
            rows_r.h_km(1), ...
            rows_r.i_deg(1), ...
            rows_r.F(1), ...
            rows_r.Ns(1), ...
            raan, ...
            dg_best_val, ...
            rows_r.P(idx_dg), ...
            rows_r.T(idx_dg), ...
            pr_best_val, ...
            rows_r.P(idx_pr), ...
            rows_r.T(idx_pr), ...
            height(rows_r) ...
            }; %#ok<AGROW>
    end

    envelope_table = cell2table(rows, 'VariableNames', { ...
        'h_km', ...
        'i_deg', ...
        'F', ...
        'Ns', ...
        'RAAN_deg', ...
        'DG_env_max', ...
        'best_P_for_DG', ...
        'best_T_for_DG', ...
        'pass_env_max', ...
        'best_P_for_pass', ...
        'best_T_for_pass', ...
        'n_designs_at_this_RAAN' ...
        });

    envelope_table = sortrows(envelope_table, 'RAAN_deg');

    tag = sprintf('h%d_i%.0f_Ns%d_F%d', ...
        round(envelope_table.h_km(1)), ...
        envelope_table.i_deg(1), ...
        envelope_table.Ns(1), ...
        envelope_table.F(1));

    files = plot_stage14_ns_envelopes(envelope_table, cfg, ...
        'visible', local.visible, ...
        'save_fig', local.save_fig, ...
        'tag', tag);

    files.table_file = '';
    if local.save_table
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        files.table_file = fullfile(cfg.paths.tables, sprintf('stage14_ns_envelope_%s_%s.csv', tag, timestamp));
        writetable(envelope_table, files.table_file);
    end

    summary = struct();
    summary.scan_file = scan_file;
    summary.n_rows = height(envelope_table);
    summary.h_km = envelope_table.h_km(1);
    summary.i_deg = envelope_table.i_deg(1);
    summary.F = envelope_table.F(1);
    summary.Ns = envelope_table.Ns(1);
    summary.DG_env_min = min(envelope_table.DG_env_max, [], 'omitnan');
    summary.DG_env_max = max(envelope_table.DG_env_max, [], 'omitnan');
    summary.DG_env_span = summary.DG_env_max - summary.DG_env_min;
    summary.pass_env_min = min(envelope_table.pass_env_max, [], 'omitnan');
    summary.pass_env_max = max(envelope_table.pass_env_max, [], 'omitnan');
    summary.pass_env_span = summary.pass_env_max - summary.pass_env_min;

    out = struct();
    out.envelope_table = envelope_table;
    out.summary = summary;
    out.files = files;

    fprintf('\n=== Stage14.2 Ns-envelope profile ===\n');
    fprintf('scan file        : %s\n', summary.scan_file);
    fprintf('filter           : h=%g, i=%g, F=%d, Ns=%d\n', ...
        summary.h_km, summary.i_deg, summary.F, summary.Ns);
    fprintf('rows             : %d\n', summary.n_rows);
    fprintf('DG_env span      : %.6f\n', summary.DG_env_span);
    fprintf('pass_env span    : %.6f\n', summary.pass_env_span);
    fprintf('DG plot          : %s\n', files.DG_env_png);
    fprintf('pass plot        : %s\n', files.pass_env_png);
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
