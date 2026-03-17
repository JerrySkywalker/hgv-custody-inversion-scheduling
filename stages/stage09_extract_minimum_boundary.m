function out = stage09_extract_minimum_boundary(stage09_4_out, cfg)
%STAGE09_EXTRACT_MINIMUM_BOUNDARY
% Stage09.5:
%   Extract minimum-size boundary and parameter ranges from Stage09.4
%   feasible-domain results.
%
% Usage:
%   out = stage09_extract_minimum_boundary();
%   out = stage09_extract_minimum_boundary(out9_4);
%   out = stage09_extract_minimum_boundary([], cfg);

    startup();

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);
    cfg.project_stage = 'stage09_extract_minimum_boundary';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    run_tag = char(cfg.stage09.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage09_extract_minimum_boundary_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage09.5 started.');

    % ------------------------------------------------------------
    % Load Stage09.4 result if not supplied
    % ------------------------------------------------------------
    if nargin < 1 || isempty(stage09_4_out)
        stage09_4_out = local_load_latest_stage09_4_cache(cfg.paths.cache, run_tag);
        log_msg(log_fid, 'INFO', 'Loaded latest Stage09.4 cache automatically.');
    end

    full_theta_table = stage09_4_out.full_theta_table;
    feasible_theta_table = stage09_4_out.feasible_theta_table;

    boundary_struct = extract_stage09_minimum_boundary(feasible_theta_table);
    table_struct = build_stage09_parameter_domain_tables( ...
        full_theta_table, feasible_theta_table, boundary_struct);

    % ------------------------------------------------------------
    % Write tables
    % ------------------------------------------------------------
    boundary_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_minimum_boundary_%s_%s.csv', run_tag, timestamp));
    theta_min_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_theta_min_set_%s_%s.csv', run_tag, timestamp));
    parameter_range_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_parameter_ranges_%s_%s.csv', run_tag, timestamp));
    PT_pairs_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_PT_pairs_at_Nmin_%s_%s.csv', run_tag, timestamp));

    writetable(table_struct.minimum_boundary_table, boundary_csv);
    writetable(table_struct.theta_min_table_sorted, theta_min_csv);
    writetable(table_struct.parameter_range_table, parameter_range_csv);
    writetable(boundary_struct.PT_pairs_at_Nmin, PT_pairs_csv);

    out = struct();
    out.cfg = cfg;
    out.N_min_rob = boundary_struct.N_min_rob;
    out.theta_min_table = boundary_struct.theta_min_table;
    out.theta_min_table_sorted = table_struct.theta_min_table_sorted;
    out.boundary_table = boundary_struct.boundary_table;
    out.parameter_range_table = table_struct.parameter_range_table;
    out.PT_pairs_at_Nmin = boundary_struct.PT_pairs_at_Nmin;
    out.h_range_at_Nmin = boundary_struct.h_range_at_Nmin;
    out.i_range_at_Nmin = boundary_struct.i_range_at_Nmin;

    out.files = struct();
    out.files.log_file = log_file;
    out.files.boundary_csv = boundary_csv;
    out.files.theta_min_csv = theta_min_csv;
    out.files.parameter_range_csv = parameter_range_csv;
    out.files.PT_pairs_csv = PT_pairs_csv;

    cache_file = fullfile(cfg.paths.cache, ...
        sprintf('stage09_extract_minimum_boundary_%s_%s.mat', run_tag, timestamp));
    save(cache_file, 'out', '-v7.3');
    out.files.cache_file = cache_file;

    log_msg(log_fid, 'INFO', 'N_min_rob = %g', out.N_min_rob);
    log_msg(log_fid, 'INFO', 'Boundary CSV saved to: %s', boundary_csv);
    log_msg(log_fid, 'INFO', 'Theta-min CSV saved to: %s', theta_min_csv);
    log_msg(log_fid, 'INFO', 'Parameter-range CSV saved to: %s', parameter_range_csv);
    log_msg(log_fid, 'INFO', 'Stage09.5 finished.');

    fprintf('\n');
    fprintf('========== Stage09.5 Minimum-Boundary Summary ==========\n');
    disp(out.boundary_table);
    disp(out.parameter_range_table);
    disp(out.PT_pairs_at_Nmin);
    fprintf('Boundary CSV       : %s\n', boundary_csv);
    fprintf('Theta-min CSV      : %s\n', theta_min_csv);
    fprintf('Parameter-range CSV: %s\n', parameter_range_csv);
    fprintf('PT-pairs CSV       : %s\n', PT_pairs_csv);
    fprintf('Cache              : %s\n', cache_file);
    fprintf('========================================================\n');
end


function out = local_load_latest_stage09_4_cache(cache_dir, run_tag)
% Load the latest stage09_build_feasible_domain cache

    pattern = sprintf('stage09_build_feasible_domain_%s_*.mat', run_tag);
    listing = find_stage_cache_files(cache_dir, pattern);

    if isempty(listing)
        pattern = 'stage09_build_feasible_domain_*.mat';
        listing = find_stage_cache_files(cache_dir, pattern);
    end

    if isempty(listing)
        error('No Stage09.4 cache found in: %s', cache_dir);
    end

    [~, idx] = max([listing.datenum]);
    cache_file = fullfile(listing(idx).folder, listing(idx).name);

    S = load(cache_file);
    if ~isfield(S, 'out')
        error('Invalid Stage09.4 cache: %s', cache_file);
    end
    out = S.out;
end
