function out = stage09_plot_inverse_design_results(out9_4, out9_5, cfg)
%STAGE09_PLOT_INVERSE_DESIGN_RESULTS
% Stage09.6:
%   Export Stage09 inverse-design figures and plotting assets.
%
% Usage:
%   out = stage09_plot_inverse_design_results();
%   out = stage09_plot_inverse_design_results(out9_4, out9_5);
%   out = stage09_plot_inverse_design_results(out9_4, out9_5, cfg);

    startup();

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);
    cfg.project_stage = 'stage09_plot_inverse_design_results';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage09.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage09_plot_inverse_design_results_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage09.6 started.');

    % ------------------------------------------------------------
    % Auto load Stage09.4 and Stage09.5 caches if needed
    % ------------------------------------------------------------
    if nargin < 1 || isempty(out9_4)
        out9_4 = local_load_latest_cache(cfg.paths.cache, ...
            sprintf('stage09_build_feasible_domain_%s_*.mat', run_tag), ...
            'stage09_build_feasible_domain_*.mat');
        log_msg(log_fid, 'INFO', 'Loaded latest Stage09.4 cache automatically.');
    end

    if nargin < 2 || isempty(out9_5)
        out9_5 = local_load_latest_cache(cfg.paths.cache, ...
            sprintf('stage09_extract_minimum_boundary_%s_*.mat', run_tag), ...
            'stage09_extract_minimum_boundary_*.mat');
        log_msg(log_fid, 'INFO', 'Loaded latest Stage09.5 cache automatically.');
    end

    pdata = struct();
    pdata.out9_4 = out9_4;
    pdata.out9_5 = out9_5;

    fig1 = plot_stage09_feasible_domain_maps(pdata, cfg, timestamp);
    fig2 = plot_stage09_minimum_boundary(pdata, cfg, timestamp);

    figure_index_table = table( ...
        string(fig1.minNs_hi), ...
        string(fig1.fail_hi_refPT), ...
        string(fig1.feasible_PT), ...
        string(fig2.Ns_vs_margin), ...
        string(fig2.theta_min_hi), ...
        'VariableNames', { ...
            'fig_minNs_hi', ...
            'fig_fail_hi_refPT', ...
            'fig_feasible_PT', ...
            'fig_Ns_vs_margin', ...
            'fig_theta_min_hi'});

    figure_index_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_figure_index_%s_%s.csv', run_tag, timestamp));
    writetable(figure_index_table, figure_index_csv);

    out = struct();
    out.figure_index_table = figure_index_table;
    out.files = struct();
    out.files.log_file = log_file;
    out.files.figure_index_csv = figure_index_csv;
    out.files.fig_minNs_hi = fig1.minNs_hi;
    out.files.fig_fail_hi_refPT = fig1.fail_hi_refPT;
    out.files.fig_feasible_PT = fig1.feasible_PT;
    out.files.fig_Ns_vs_margin = fig2.Ns_vs_margin;
    out.files.fig_theta_min_hi = fig2.theta_min_hi;

    cache_file = fullfile(cfg.paths.cache, ...
        sprintf('stage09_plot_inverse_design_results_%s_%s.mat', run_tag, timestamp));
    save(cache_file, 'out', '-v7.3');
    out.files.cache_file = cache_file;

    log_msg(log_fid, 'INFO', 'Figure index CSV saved to: %s', figure_index_csv);
    log_msg(log_fid, 'INFO', 'Stage09.6 finished.');

    fprintf('\n');
    fprintf('========== Stage09.6 Figure Export Summary ==========\n');
    disp(figure_index_table);
    fprintf('Figure index CSV : %s\n', figure_index_csv);
    fprintf('Cache            : %s\n', cache_file);
    fprintf('=====================================================\n');
end


function out = local_load_latest_cache(cache_dir, pattern1, pattern2)

    listing = find_stage_cache_files(cache_dir, pattern1);
    if isempty(listing)
        listing = find_stage_cache_files(cache_dir, pattern2);
    end
    if isempty(listing)
        error('No cache matched patterns: %s / %s', pattern1, pattern2);
    end

    [~, idx] = max([listing.datenum]);
    cache_file = fullfile(listing(idx).folder, listing(idx).name);

    S = load(cache_file);
    if ~isfield(S, 'out')
        error('Invalid cache file: %s', cache_file);
    end
    out = S.out;
end
