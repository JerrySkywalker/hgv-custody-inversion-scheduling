function out = stage09_validate_window_kernel(cfg)
%STAGE09_VALIDATE_WINDOW_KERNEL
% Stage09.2 validation script for the window metric kernel.
%
% This script validates:
%   1) stronger Wr -> larger DG, larger DA
%   2) direction-sensitive CA projection affects DA
%   3) mildly singular Wr can still be handled numerically

    cfg_missing = (nargin < 1 || isempty(cfg));
    if cfg_missing
        evalc('startup(''force'', false);');
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);
    cfg.project_stage = 'stage09_validate_window_kernel';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    run_tag = char(cfg.stage09.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage09_validate_window_kernel_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage09.2 validation started.');

    s9 = cfg.stage09;
    s9.gamma_eff_scalar = 1.0;
    s9.sigma_A_req = 1.0;

    % ------------------------------------------------------------
    % Test set
    % ------------------------------------------------------------
    Wr_weak   = diag([1e-2, 2e-2, 5e-2]);
    Wr_medium = diag([1e-1, 2e-1, 5e-1]);
    Wr_strong = diag([1, 2, 5]);

    % direction-sensitive projection: focus on x-direction
    s9_x = s9;
    s9_x.CA_mode = 'custom';
    s9_x.CA = [1 0 0];

    % direction-sensitive projection: focus on z-direction
    s9_z = s9;
    s9_z.CA_mode = 'custom';
    s9_z.CA = [0 0 1];

    % nearly singular but still regularized
    Wr_near_sing = diag([1e-12, 1e-4, 1e-1]);

    rows = {};

    rows{end+1} = local_eval_row('weak_xyz', Wr_weak,   s9);   %#ok<AGROW>
    rows{end+1} = local_eval_row('medium_xyz', Wr_medium, s9); %#ok<AGROW>
    rows{end+1} = local_eval_row('strong_xyz', Wr_strong, s9); %#ok<AGROW>
    rows{end+1} = local_eval_row('medium_x', Wr_medium,  s9_x); %#ok<AGROW>
    rows{end+1} = local_eval_row('medium_z', Wr_medium,  s9_z); %#ok<AGROW>
    rows{end+1} = local_eval_row('near_sing_xyz', Wr_near_sing, s9); %#ok<AGROW>

    result_table = struct2table(vertcat(rows{:}));

    % quick monotonic checks
    pass_DG_monotonic = ...
        result_table.DG(strcmp(result_table.case_name, 'weak_xyz')) < ...
        result_table.DG(strcmp(result_table.case_name, 'medium_xyz')) && ...
        result_table.DG(strcmp(result_table.case_name, 'medium_xyz')) < ...
        result_table.DG(strcmp(result_table.case_name, 'strong_xyz'));

    pass_DA_monotonic = ...
        result_table.DA(strcmp(result_table.case_name, 'weak_xyz')) < ...
        result_table.DA(strcmp(result_table.case_name, 'medium_xyz')) && ...
        result_table.DA(strcmp(result_table.case_name, 'medium_xyz')) < ...
        result_table.DA(strcmp(result_table.case_name, 'strong_xyz'));

    check_table = table( ...
        logical(pass_DG_monotonic), ...
        logical(pass_DA_monotonic), ...
        'VariableNames', {'pass_DG_monotonic', 'pass_DA_monotonic'});

    result_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_validate_window_kernel_%s_%s.csv', run_tag, timestamp));
    check_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_validate_window_kernel_checks_%s_%s.csv', run_tag, timestamp));
    writetable(result_table, result_csv);
    writetable(check_table, check_csv);

    out = struct();
    out.result_table = result_table;
    out.check_table = check_table;
    out.files = struct();
    out.files.result_csv = result_csv;
    out.files.check_csv = check_csv;
    out.files.log_file = log_file;

    cache_file = fullfile(cfg.paths.cache, ...
        sprintf('stage09_validate_window_kernel_%s_%s.mat', run_tag, timestamp));
    save(cache_file, 'out', '-v7.3');
    out.files.cache_file = cache_file;

    log_msg(log_fid, 'INFO', 'Validation CSV saved to: %s', result_csv);
    log_msg(log_fid, 'INFO', 'Validation check CSV saved to: %s', check_csv);
    log_msg(log_fid, 'INFO', 'Stage09.2 validation finished.');

    fprintf('\n');
    fprintf('========== Stage09.2 Validation ==========\n');
    disp(result_table);
    disp(check_table);
    fprintf('Result CSV : %s\n', result_csv);
    fprintf('Check CSV  : %s\n', check_csv);
    fprintf('Cache      : %s\n', cache_file);
    fprintf('==========================================\n');
end


function row = local_eval_row(case_name, Wr, s9)

    m = compute_window_metrics_stage09(Wr, s9);

    row = struct();
    row.case_name = string(case_name);
    row.lambda_min_raw = m.lambda_min_raw;
    row.lambda_min_eff = m.lambda_min_eff;
    row.DG = m.DG;
    row.sigma_A_proj = m.sigma_A_proj;
    row.DA = m.DA;
    row.Wr_cond = m.Wr_cond;
    row.rank_Wr = m.rank_Wr;
    row.ok = m.ok;
    row.note = string(m.note);
end
