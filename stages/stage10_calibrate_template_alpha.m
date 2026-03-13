function out = stage10_calibrate_template_alpha(cfg)
%STAGE10_CALIBRATE_TEMPLATE_ALPHA
% Stage10.1d:
%   calibrate template_alpha_per_obs on a fixed case / theta / window.
%
% Strategy:
%   - reuse stage10_validate_single_window_fft(cfg)
%   - scan cfg.stage10.alpha_grid
%   - compare lambda_blk_fft_eff against lambda_full_eff
%   - pick best alpha under selected fit metric

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10_prepare_cfg(cfg);
    cfg.project_stage = 'stage10_calibrate_template_alpha';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    run_tag = char(cfg.stage10.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10_calibrate_template_alpha_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.1d calibration started.');
    log_msg(log_fid, 'INFO', 'alpha grid = %s', mat2str(cfg.stage10.alpha_grid));

    alpha_grid = cfg.stage10.alpha_grid(:);
    nA = numel(alpha_grid);

    alpha_val = nan(nA,1);
    lambda_full_eff = nan(nA,1);
    lambda_fft_eff = nan(nA,1);
    abs_err_lambda = nan(nA,1);
    rel_err_lambda = nan(nA,1);
    eps_sb_fro = nan(nA,1);
    eps_sb_2 = nan(nA,1);
    bound_hit_flag = false(nA,1);

    out_bank = cell(nA,1);

    for i = 1:nA
        alpha_i = alpha_grid(i);
        cfg_i = cfg;
        cfg_i.stage10.mode = 'single_window_debug';
        cfg_i.stage10.template_alpha_per_obs = alpha_i;

        log_msg(log_fid, 'INFO', 'Calibration run %d/%d, alpha=%.6g', i, nA, alpha_i);

        out_i = stage10_validate_single_window_fft(cfg_i);
        out_bank{i} = out_i;

        T = out_i.summary_table;
        alpha_val(i) = alpha_i;
        lambda_full_eff(i) = T.lambda_full_eff(1);
        lambda_fft_eff(i) = T.lambda_blk_fft_eff(1);
        abs_err_lambda(i) = T.abs_err_lambda(1);
        rel_err_lambda(i) = T.rel_err_lambda(1);
        eps_sb_fro(i) = T.eps_sb_fro(1);
        eps_sb_2(i) = T.eps_sb_2(1);
        bound_hit_flag(i) = logical(T.bound_hit_flag(1));
    end

    calib_table = table( ...
        alpha_val, lambda_full_eff, lambda_fft_eff, ...
        abs_err_lambda, rel_err_lambda, eps_sb_fro, eps_sb_2, bound_hit_flag, ...
        'VariableNames', { ...
            'alpha_per_obs', 'lambda_full_eff', 'lambda_fft_eff', ...
            'abs_err_lambda', 'rel_err_lambda', 'eps_sb_fro', 'eps_sb_2', 'bound_hit_flag'});

    switch lower(string(cfg.stage10.alpha_fit_metric))
        case "lambda_abs_error"
            fit_score = abs_err_lambda;
        case "lambda_rel_error"
            fit_score = rel_err_lambda;
        otherwise
            error('Unknown alpha_fit_metric: %s', string(cfg.stage10.alpha_fit_metric));
    end

    [~, idx_best] = min(fit_score);
    best_alpha = alpha_val(idx_best);

    best_summary = calib_table(idx_best,:);

    log_msg(log_fid, 'INFO', 'Best alpha = %.6g', best_alpha);
    log_msg(log_fid, 'INFO', 'Best metric value = %.6g', fit_score(idx_best));

    out = struct();
    out.cfg = cfg;
    out.alpha_grid = alpha_grid;
    out.calib_table = calib_table;
    out.best_idx = idx_best;
    out.best_alpha = best_alpha;
    out.best_summary = best_summary;
    out.out_bank = out_bank;
    out.files = struct();
    out.files.log_file = log_file;

    if cfg.stage10.write_csv
        calib_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10_alpha_calibration_%s_%s.csv', run_tag, timestamp));
        writetable(calib_table, calib_csv);
        out.files.calib_csv = calib_csv;
        log_msg(log_fid, 'INFO', 'Calibration CSV saved to: %s', calib_csv);
    end

    if cfg.stage10.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10_alpha_calibration_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Calibration MAT saved to: %s', cache_file);
    end

    fprintf('\n');
    fprintf('========== Stage10.1d Alpha Calibration ==========\n');
    disp(calib_table);
    fprintf('Best alpha_per_obs = %.6g\n', best_alpha);
    disp(best_summary);
    if isfield(out.files, 'calib_csv')
        fprintf('Calibration CSV : %s\n', out.files.calib_csv);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache          : %s\n', out.files.cache_file);
    end
    fprintf('Log            : %s\n', out.files.log_file);
    fprintf('==================================================\n');
end