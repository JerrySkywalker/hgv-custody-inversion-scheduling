function out = stage10D_symmetry_breaking_margin(cfg)
%STAGE10D_SYMMETRY_BREAKING_MARGIN
% Stage10.D:
%   Analyze symmetry-breaking relative to the legal baseline using
%   truth / zero-mode / bcirc-min comparison.
%
% This stage emphasizes:
%   - zero mode often preserves the main spectral content of truth
%   - legal bcirc minimum may be much more conservative
%   - eps_sb is computed in a dimension-consistent way:
%       eps_sb = ||W_r - A_0||_2

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10D_prepare_cfg(cfg);
    cfg.project_stage = 'stage10D_symmetry_breaking_margin';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage10D.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10D_symmetry_breaking_margin_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.D symmetry-breaking margin started.');

    % ------------------------------------------------------------
    % Reuse Stage10.C
    % ------------------------------------------------------------
    cfgC = cfg;
    cfgC.stage10C.run_tag = [run_tag '_C'];
    cfgC.stage10C.case_source = cfg.stage10D.case_source;
    cfgC.stage10C.theta_source = cfg.stage10D.theta_source;
    cfgC.stage10C.manual_theta = cfg.stage10D.manual_theta;
    cfgC.stage10C.case_index = cfg.stage10D.case_index;
    cfgC.stage10C.window_index = cfg.stage10D.window_index;
    cfgC.stage10C.clip_case_index = cfg.stage10D.clip_case_index;
    cfgC.stage10C.clip_window_index = cfg.stage10D.clip_window_index;
    cfgC.stage10C.anchor_mode = cfg.stage10D.anchor_mode;
    cfgC.stage10C.manual_anchor_plane = cfg.stage10D.manual_anchor_plane;
    cfgC.stage10C.prototype_source = cfg.stage10D.prototype_source;
    cfgC.stage10C.make_plot = false;
    cfgC.stage10C.write_csv = false;
    cfgC.stage10C.save_mat_cache = false;

    outC = stage10C_fft_spectral_validation(cfgC);

    Wtruth = outC.outB1.outB.outA.Wr_full;
    A0 = outC.spec.mode_blocks(:,:,1);   % zero mode block
    lambda_min_bcirc = outC.summary_table.lambda_min_bcirc(1);

    eps_pack = compute_eps_sb_stage10D(Wtruth, A0, cfg);

    meta = struct();
    meta.case_id = char(outC.outB1.outB.outA.case.case_id);
    meta.family = char(local_safe_get(outC.outB1.outB.outA.case, 'family', ""));
    meta.h_km = outC.outB1.outB.outA.theta_row.h_km;
    meta.i_deg = outC.outB1.outB.outA.theta_row.i_deg;
    meta.P_theta = outC.outB1.outB.outA.theta_row.P;
    meta.T_theta = outC.outB1.outB.outA.theta_row.T;
    meta.F_theta = outC.outB1.outB.outA.theta_row.F;
    meta.Ns_theta = outC.outB1.outB.outA.theta_row.Ns;
    meta.window_index = outC.outB1.outB.outA.window_index;
    meta.t0_s = outC.outB1.outB.outA.window_info.t0_s;
    meta.t1_s = outC.outB1.outB.outA.window_info.t1_s;

    [summary_table, eig_table] = build_stage10D_bound_table( ...
        Wtruth, A0, lambda_min_bcirc, outC.spec, eps_pack, meta, cfg);

    out = struct();
    out.cfg = cfg;
    out.outC = outC;
    out.Wtruth = Wtruth;
    out.A0 = A0;
    out.eps_pack = eps_pack;
    out.summary_table = summary_table;
    out.eig_table = eig_table;
    out.mode_table = outC.mode_table;
    out.files = struct();
    out.files.log_file = log_file;

    % ------------------------------------------------------------
    % Save tables
    % ------------------------------------------------------------
    if cfg.stage10D.write_csv
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10D_margin_summary_%s_%s.csv', run_tag, timestamp));
        eig_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10D_margin_eigs_%s_%s.csv', run_tag, timestamp));
        mode_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10D_margin_mode_table_%s_%s.csv', run_tag, timestamp));

        writetable(summary_table, summary_csv);
        writetable(eig_table, eig_csv);
        writetable(outC.mode_table, mode_csv);

        out.files.summary_csv = summary_csv;
        out.files.eig_csv = eig_csv;
        out.files.mode_csv = mode_csv;

        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Eig CSV saved to: %s', eig_csv);
        log_msg(log_fid, 'INFO', 'Mode CSV saved to: %s', mode_csv);
    end

    % ------------------------------------------------------------
    % Plot
    % ------------------------------------------------------------
    if cfg.stage10D.make_plot
        fig_png = fullfile(cfg.paths.figs, ...
            sprintf('stage10D_margin_structure_%s_%s.png', run_tag, timestamp));
        fig = plot_stage10D_margin_analysis(summary_table, eig_table, outC.mode_table, fig_png);
        out.files.fig_png = fig_png;
        out.fig = fig;
        log_msg(log_fid, 'INFO', 'Figure saved to: %s', fig_png);
    end

    % ------------------------------------------------------------
    % Cache
    % ------------------------------------------------------------
    if cfg.stage10D.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10D_margin_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.D symmetry-breaking margin finished.');

    fprintf('\n');
    fprintf('========== Stage10.D symmetry-breaking margin ==========\n');
    disp(summary_table);
    disp(eig_table);
    disp(outC.mode_table);
    if isfield(out.files, 'summary_csv')
        fprintf('Summary CSV : %s\n', out.files.summary_csv);
    end
    if isfield(out.files, 'eig_csv')
        fprintf('Eig CSV     : %s\n', out.files.eig_csv);
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
    fprintf('========================================================\n');
end


function value = local_safe_get(s, field_name, default_value)
    if isfield(s, field_name)
        value = s.(field_name);
    else
        value = default_value;
    end
end
