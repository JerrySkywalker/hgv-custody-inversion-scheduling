function out = stage10C_fft_spectral_validation(cfg)
%STAGE10C_FFT_SPECTRAL_VALIDATION
% Stage10.C:
%   Validate the FFT spectral decomposition of the legal bcirc baseline.
%
% Outputs:
%   - legal first-column blocks
%   - mode blocks A_k
%   - mode-wise spectra
%   - consistency check between full bcirc eig and FFT mode-min eig
%   - preliminary truth vs bcirc spectral comparison

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10C_prepare_cfg(cfg);
    cfg.project_stage = 'stage10C_fft_spectral_validation';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage10C.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10C_fft_spectral_validation_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.C FFT spectral validation started.');

    % ------------------------------------------------------------
    % Reuse Stage10.B.1 legal baseline construction
    % ------------------------------------------------------------
    cfgB1 = cfg;
    cfgB1.stage10B1.run_tag = [run_tag '_B1'];
    cfgB1.stage10B1.case_source = cfg.stage10C.case_source;
    cfgB1.stage10B1.theta_source = cfg.stage10C.theta_source;
    cfgB1.stage10B1.manual_theta = cfg.stage10C.manual_theta;
    cfgB1.stage10B1.case_index = cfg.stage10C.case_index;
    cfgB1.stage10B1.window_index = cfg.stage10C.window_index;
    cfgB1.stage10B1.clip_case_index = cfg.stage10C.clip_case_index;
    cfgB1.stage10B1.clip_window_index = cfg.stage10C.clip_window_index;
    cfgB1.stage10B1.anchor_mode = cfg.stage10C.anchor_mode;
    cfgB1.stage10B1.manual_anchor_plane = cfg.stage10C.manual_anchor_plane;
    cfgB1.stage10B1.prototype_source = cfg.stage10C.prototype_source;
    cfgB1.stage10B1.make_plot = false;
    cfgB1.stage10B1.write_csv = false;
    cfgB1.stage10B1.save_mat_cache = false;

    outB1 = stage10B1_legalize_bcirc_reference(cfgB1);

    first_col_legal = outB1.first_col_legal;
    Wlegal = outB1.Wlegal;
    lambda_min_bcirc = outB1.summary_table.lambda_min_legal_bcirc(1);
    lambda_full_eff = outB1.summary_table.lambda_full_eff(1);

    % ------------------------------------------------------------
    % FFT mode decomposition
    % ------------------------------------------------------------
    spec = bcirc_fft_minEig_stage10C(first_col_legal, cfg);

    lambda_min_fft = spec.lambda_min_fft;
    lambda_zero_mode = spec.lambda_zero_mode;
    mode_argmin = spec.mode_argmin;

    fft_consistency_abs_err = abs(lambda_min_bcirc - lambda_min_fft);
    denom = max(abs(lambda_min_bcirc), eps);
    fft_consistency_rel_err = fft_consistency_abs_err / denom;

    bcirc_vs_truth_abs_gap = abs(lambda_min_bcirc - lambda_full_eff);
    bcirc_vs_truth_rel_gap = bcirc_vs_truth_abs_gap / max(abs(lambda_full_eff), eps);

    summary_table = table( ...
        string(outB1.outB.outA.case.case_id), ...
        string(local_safe_get(outB1.outB.outA.case, 'family', "")), ...
        outB1.outB.outA.theta_row.h_km, outB1.outB.outA.theta_row.i_deg, outB1.outB.outA.theta_row.P, outB1.outB.outA.theta_row.T, outB1.outB.outA.theta_row.F, outB1.outB.outA.theta_row.Ns, ...
        outB1.outB.outA.window_index, outB1.outB.outA.window_info.t0_s, outB1.outB.outA.window_info.t1_s, ...
        lambda_full_eff, ...
        lambda_min_bcirc, ...
        lambda_min_fft, ...
        fft_consistency_abs_err, ...
        fft_consistency_rel_err, ...
        mode_argmin, ...
        lambda_zero_mode, ...
        bcirc_vs_truth_abs_gap, ...
        bcirc_vs_truth_rel_gap, ...
        'VariableNames', { ...
            'case_id','family', ...
            'h_km','i_deg','P_theta','T_theta','F_theta','Ns_theta', ...
            'window_index','t0_s','t1_s', ...
            'lambda_full_eff', ...
            'lambda_min_bcirc', ...
            'lambda_min_fft', ...
            'fft_consistency_abs_err', ...
            'fft_consistency_rel_err', ...
            'mode_argmin', ...
            'lambda_zero_mode', ...
            'bcirc_vs_truth_abs_gap', ...
            'bcirc_vs_truth_rel_gap'});

    out = struct();
    out.cfg = cfg;
    out.outB1 = outB1;
    out.first_col_legal = first_col_legal;
    out.Wlegal = Wlegal;
    out.spec = spec;
    out.summary_table = summary_table;
    out.mode_table = spec.mode_table;
    out.files = struct();
    out.files.log_file = log_file;

    % ------------------------------------------------------------
    % Save tables
    % ------------------------------------------------------------
    if cfg.stage10C.write_csv
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10C_fftspec_summary_%s_%s.csv', run_tag, timestamp));
        mode_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10C_fftspec_mode_table_%s_%s.csv', run_tag, timestamp));

        writetable(summary_table, summary_csv);
        writetable(spec.mode_table, mode_csv);

        out.files.summary_csv = summary_csv;
        out.files.mode_csv = mode_csv;

        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Mode CSV saved to: %s', mode_csv);
    end

    % ------------------------------------------------------------
    % Plot
    % ------------------------------------------------------------
    if cfg.stage10C.make_plot
        fig_png = fullfile(cfg.paths.figs, ...
            sprintf('stage10C_fftspec_structure_%s_%s.png', run_tag, timestamp));
        fig = plot_stage10C_mode_spectrum(summary_table, spec.mode_table, fig_png);
        out.files.fig_png = fig_png;
        out.fig = fig;
        log_msg(log_fid, 'INFO', 'Figure saved to: %s', fig_png);
    end

    % ------------------------------------------------------------
    % Cache
    % ------------------------------------------------------------
    if cfg.stage10C.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10C_fftspec_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.C FFT spectral validation finished.');

    fprintf('\n');
    fprintf('========== Stage10.C FFT spectral validation ==========\n');
    disp(summary_table);
    disp(spec.mode_table);
    if isfield(out.files, 'summary_csv')
        fprintf('Summary CSV : %s\n', out.files.summary_csv);
    end
    if isfield(out.files, 'mode_csv')
        fprintf('Mode CSV    : %s\n', out.files.mode_csv);
    end
    if isfield(out.files, 'fig_png')
        fprintf('Figure      : %s\n', out.files.fig_png);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache       : %s\n', out.files.cache_file);
    end
    fprintf('Log         : %s\n', out.files.log_file);
    fprintf('=======================================================\n');
end


function value = local_safe_get(s, field_name, default_value)
    if isfield(s, field_name)
        value = s.(field_name);
    else
        value = default_value;
    end
end