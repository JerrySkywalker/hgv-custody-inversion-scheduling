function out = stage09_prepare_task_spec(cfg)
%STAGE09_PREPARE_TASK_SPEC
% Stage09.1:
%   Freeze the inverse-design task specification for Stage09.
%
% Main outputs:
%   out.task_spec_table
%   out.threshold_spec_table
%   out.search_domain_table
%   out.stage08_5_info
%   out.files
%
% Purpose:
%   1) inherit/freeze the standard window Tw_star
%   2) freeze formal thresholds for D_G / D_A / D_T
%   3) freeze the Stage09 search domain
%   4) save a reusable cache for later Stage09 sub-stages

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);
    cfg.project_stage = 'stage09_prepare_task_spec';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage09.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage09_prepare_task_spec_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage09.1 started.');

    % ------------------------------------------------------------
    % Resolve Tw_star
    % ------------------------------------------------------------
    stage08_5_info = struct();
    switch lower(string(cfg.stage09.Tw_source))
        case "inherit_stage08_5"
            stage08_5_info = load_latest_stage08_5_result( ...
                cfg.paths.cache, cfg.stage09.stage08_5_run_tag_hint);
            cfg.stage09.Tw_star_s = stage08_5_info.Tw_star;
            log_msg(log_fid, 'INFO', 'Inherited Tw_star = %.3f s from Stage08.5: %s', ...
                cfg.stage09.Tw_star_s, stage08_5_info.cache_file);

        case "manual"
            cfg.stage09.Tw_star_s = cfg.stage09.Tw_manual_s;
            stage08_5_info = struct();
            stage08_5_info.cache_file = "";
            stage08_5_info.Tw_star = cfg.stage09.Tw_star_s;
            stage08_5_info.recommended_row = table();
            log_msg(log_fid, 'INFO', 'Using manual Tw_star = %.3f s', cfg.stage09.Tw_star_s);

        otherwise
            error('Unsupported cfg.stage09.Tw_source: %s', string(cfg.stage09.Tw_source));
    end

    % ------------------------------------------------------------
    % Resolve gamma source description
    % ------------------------------------------------------------
    gamma_source_label = local_resolve_gamma_source_label(cfg);

    % ------------------------------------------------------------
    % Build summary tables
    % ------------------------------------------------------------
    task_spec_table = local_build_task_spec_table(cfg, stage08_5_info);
    threshold_spec_table = local_build_threshold_spec_table(cfg, gamma_source_label);
    search_domain_table = local_build_search_domain_table(cfg);

    % ------------------------------------------------------------
    % Save CSV tables
    % ------------------------------------------------------------
    task_spec_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_task_spec_%s_%s.csv', run_tag, timestamp));
    threshold_spec_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_threshold_spec_%s_%s.csv', run_tag, timestamp));
    search_domain_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_search_domain_%s_%s.csv', run_tag, timestamp));
    summary_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_prepare_task_spec_summary_%s_%s.csv', run_tag, timestamp));

    writetable(task_spec_table, task_spec_csv);
    writetable(threshold_spec_table, threshold_spec_csv);
    writetable(search_domain_table, search_domain_csv);

    summary_table = table( ...
        string(cfg.stage09.Tw_source), ...
        cfg.stage09.Tw_star_s, ...
        string(cfg.stage09.CA_mode), ...
        cfg.stage09.sigma_A_req, ...
        cfg.stage09.dt_crit_s, ...
        height(search_domain_table), ...
        'VariableNames', { ...
            'Tw_source', ...
            'Tw_star_s', ...
            'CA_mode', ...
            'sigma_A_req', ...
            'dt_crit_s', ...
            'n_search_rows'});
    writetable(summary_table, summary_csv);

    % ------------------------------------------------------------
    % Save MAT cache
    % ------------------------------------------------------------
    out = struct();
    out.cfg = cfg;
    out.stage08_5_info = stage08_5_info;
    out.task_spec_table = task_spec_table;
    out.threshold_spec_table = threshold_spec_table;
    out.search_domain_table = search_domain_table;

    out.files = struct();
    out.files.log_file = log_file;
    out.files.task_spec_csv = task_spec_csv;
    out.files.threshold_spec_csv = threshold_spec_csv;
    out.files.search_domain_csv = search_domain_csv;
    out.files.summary_csv = summary_csv;

    cache_file = fullfile(cfg.paths.cache, ...
        sprintf('stage09_prepare_task_spec_%s_%s.mat', run_tag, timestamp));
    save(cache_file, 'out', '-v7.3');
    out.files.cache_file = cache_file;

    log_msg(log_fid, 'INFO', 'Task spec CSV saved to: %s', task_spec_csv);
    log_msg(log_fid, 'INFO', 'Threshold spec CSV saved to: %s', threshold_spec_csv);
    log_msg(log_fid, 'INFO', 'Search domain CSV saved to: %s', search_domain_csv);
    log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
    log_msg(log_fid, 'INFO', 'Stage09.1 finished.');

    fprintf('\n');
    fprintf('========== Stage09.1 Summary ==========\n');
    fprintf('Tw source            : %s\n', cfg.stage09.Tw_source);
    fprintf('Tw_star [s]          : %.3f\n', cfg.stage09.Tw_star_s);
    fprintf('CA mode              : %s\n', cfg.stage09.CA_mode);
    fprintf('sigma_A_req          : %.6g (%s)\n', ...
        cfg.stage09.sigma_A_req, cfg.stage09.sigma_A_req_unit);
    fprintf('dt_crit [s]          : %.3f\n', cfg.stage09.dt_crit_s);
    fprintf('Search rows          : %d\n', height(search_domain_table));
    fprintf('Task spec CSV        : %s\n', task_spec_csv);
    fprintf('Threshold spec CSV   : %s\n', threshold_spec_csv);
    fprintf('Search domain CSV    : %s\n', search_domain_csv);
    fprintf('Cache                : %s\n', cache_file);
    fprintf('=======================================\n');
end


function gamma_source_label = local_resolve_gamma_source_label(cfg)

    switch lower(string(cfg.stage09.gamma_source))
        case "inherit_stage04"
            gamma_source_label = "inherit_stage04";
        otherwise
            gamma_source_label = string(cfg.stage09.gamma_source);
    end
end


function T = local_build_task_spec_table(cfg, stage08_5_info)

    source_file = "";
    if isstruct(stage08_5_info) && isfield(stage08_5_info, 'cache_file')
        source_file = string(stage08_5_info.cache_file);
    end

    T = table( ...
        string(cfg.stage09.task_name), ...
        string(cfg.stage09.region_label), ...
        string(cfg.stage09.g_max_label), ...
        cfg.stage09.g_max_value, ...
        string(cfg.stage09.g_max_unit), ...
        string(cfg.stage09.Tw_source), ...
        cfg.stage09.Tw_star_s, ...
        source_file, ...
        string(cfg.stage09.CA_mode), ...
        string(cfg.stage09.CA_label), ...
        'VariableNames', { ...
            'task_name', ...
            'region_label', ...
            'g_max_label', ...
            'g_max_value', ...
            'g_max_unit', ...
            'Tw_source', ...
            'Tw_star_s', ...
            'Tw_source_file', ...
            'CA_mode', ...
            'CA_label'});
end


function T = local_build_threshold_spec_table(cfg, gamma_source_label)

    T = table( ...
        gamma_source_label, ...
        cfg.stage09.sigma_A_req, ...
        string(cfg.stage09.sigma_A_req_unit), ...
        cfg.stage09.dt_crit_s, ...
        string(cfg.stage09.rank_rule), ...
        'VariableNames', { ...
            'gamma_source', ...
            'sigma_A_req', ...
            'sigma_A_req_unit', ...
            'dt_crit_s', ...
            'rank_rule'});
end


function T = local_build_search_domain_table(cfg)

    h_grid = cfg.stage09.search_domain.h_grid_km(:);
    i_grid = cfg.stage09.search_domain.i_grid_deg(:);
    P_grid = cfg.stage09.search_domain.P_grid(:);
    T_grid = cfg.stage09.search_domain.T_grid(:);
    F_fixed = cfg.stage09.search_domain.F_fixed;

    rows = cell(numel(h_grid) * numel(i_grid) * numel(P_grid) * numel(T_grid), 1);
    idx = 0;

    for ih = 1:numel(h_grid)
        for ii = 1:numel(i_grid)
            for ip = 1:numel(P_grid)
                for it = 1:numel(T_grid)
                    idx = idx + 1;
                    r = struct();
                    r.h_km = h_grid(ih);
                    r.i_deg = i_grid(ii);
                    r.P = P_grid(ip);
                    r.T = T_grid(it);
                    r.F = F_fixed;
                    r.Ns = P_grid(ip) * T_grid(it);
                    rows{idx} = r;
                end
            end
        end
    end

    T = struct2table(vertcat(rows{:}));
    T = sortrows(T, {'Ns','h_km','i_deg','P','T'}, {'ascend','ascend','ascend','ascend','ascend'});

    if isfinite(cfg.stage09.search_domain.max_config_count)
        T = T(1:min(height(T), cfg.stage09.search_domain.max_config_count), :);
    end
end
