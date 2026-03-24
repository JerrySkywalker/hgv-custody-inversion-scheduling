function out = stage10B1_legalize_bcirc_reference(cfg)
%STAGE10B1_LEGALIZE_BCIRC_REFERENCE
% Stage10.B.1:
%   Legalize the Stage10.B bcirc prototype by
%   1) mirror-compatibility enforcement on first-column blocks
%   2) PSD projection in Fourier mode space
%
% This stage outputs a legal bcirc baseline candidate W_{r,0}.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10B1_prepare_cfg(cfg);
    cfg.project_stage = 'stage10B1_legalize_bcirc_reference';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage10B1.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10B1_legalize_bcirc_reference_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.B.1 bcirc legalization started.');

    % ------------------------------------------------------------
    % Reuse Stage10.B prototype construction
    % ------------------------------------------------------------
    cfgB = cfg;
    cfgB.stage10B.run_tag = [run_tag '_B'];
    cfgB.stage10B.case_source = cfg.stage10B1.case_source;
    cfgB.stage10B.theta_source = cfg.stage10B1.theta_source;
    cfgB.stage10B.manual_theta = cfg.stage10B1.manual_theta;
    cfgB.stage10B.case_index = cfg.stage10B1.case_index;
    cfgB.stage10B.window_index = cfg.stage10B1.window_index;
    cfgB.stage10B.clip_case_index = cfg.stage10B1.clip_case_index;
    cfgB.stage10B.clip_window_index = cfg.stage10B1.clip_window_index;
    cfgB.stage10B.anchor_mode = cfg.stage10B1.anchor_mode;
    cfgB.stage10B.manual_anchor_plane = cfg.stage10B1.manual_anchor_plane;
    cfgB.stage10B.bcirc_firstcol_source = cfg.stage10B1.prototype_source;
    cfgB.stage10B.truth_reduced_source = cfg.stage10B1.prototype_source;
    cfgB.stage10B.make_plot = false;
    cfgB.stage10B.write_csv = false;
    cfgB.stage10B.save_mat_cache = false;

    outB = stage10B_build_bcirc_reference(cfgB);

    first_col_proto = outB.bcirc_pack.first_col_blocks_3x3xP;
    Wproto = outB.Wbcirc;
    truth_blocks = outB.truth_blocks;

    % ------------------------------------------------------------
    % Step 1: mirror compatibility
    % ------------------------------------------------------------
    sym_out = symmetrize_firstcol_bcirc_stage10B1(first_col_proto, cfg);
    first_col_sym = sym_out.first_col_blocks_sym;

    % ------------------------------------------------------------
    % Step 2: PSD projection in Fourier mode space
    % ------------------------------------------------------------
    psd_out = project_bcirc_psd_stage10B1(first_col_sym, cfg);
    first_col_legal = psd_out.first_col_blocks_psd;

    Wlegal = reconstruct_bcirc_matrix_stage10B(reconstructable_firstcol(first_col_legal), cfg);

    % ------------------------------------------------------------
    % Consistency checks
    % ------------------------------------------------------------
    chk_proto = check_bcirc_consistency_stage10B(Wproto, first_col_proto, truth_blocks, cfg);
    chk_legal = check_bcirc_consistency_stage10B(Wlegal, first_col_legal, truth_blocks, cfg);

    legal_vs_proto_fro = norm(Wlegal - Wproto, 'fro');
    legal_vs_proto_2 = norm(Wlegal - Wproto, 2);

    % ------------------------------------------------------------
    % Tables
    % ------------------------------------------------------------
    P = size(first_col_proto, 3);

    firstcol_before_table = local_firstcol_table(first_col_proto);
    firstcol_after_table = local_firstcol_table(first_col_legal);

    mode_table = table( ...
        (0:P-1).', psd_out.lambda_mode_min_before, psd_out.lambda_mode_min_after, ...
        'VariableNames', {'mode_index','lambda_mode_min_before','lambda_mode_min_after'});

    summary_table = table( ...
        string(outB.outA.case.case_id), ...
        string(local_safe_get(outB.outA.case, 'family', "")), ...
        outB.outA.theta_row.h_km, outB.outA.theta_row.i_deg, outB.outA.theta_row.P, outB.outA.theta_row.T, outB.outA.theta_row.F, outB.outA.theta_row.Ns, ...
        outB.outA.window_index, outB.outA.window_info.t0_s, outB.outA.window_info.t1_s, ...
        outB.outA.summary_table.lambda_full_eff(1), ...
        outB.outA.summary_table.n_active_plane(1), ...
        outB.outA.summary_table.active_ratio(1), ...
        sym_out.mirror_gap_before, sym_out.mirror_gap_after, ...
        chk_proto.lambda_min_bcirc, chk_legal.lambda_min_bcirc, ...
        chk_proto.self_firstcol_err_fro, chk_legal.self_firstcol_err_fro, ...
        legal_vs_proto_fro, legal_vs_proto_2, ...
        chk_legal.bcirc_vs_truth_reduced_fro, chk_legal.bcirc_vs_truth_reduced_2, ...
        'VariableNames', { ...
            'case_id','family', ...
            'h_km','i_deg','P_theta','T_theta','F_theta','Ns_theta', ...
            'window_index','t0_s','t1_s', ...
            'lambda_full_eff', ...
            'n_active_plane','active_ratio', ...
            'mirror_gap_before','mirror_gap_after', ...
            'lambda_min_proto_bcirc','lambda_min_legal_bcirc', ...
            'self_err_proto_fro','self_err_legal_fro', ...
            'legal_vs_proto_fro','legal_vs_proto_2', ...
            'legal_vs_truth_reduced_fro','legal_vs_truth_reduced_2'});

    out = struct();
    out.cfg = cfg;
    out.outB = outB;
    out.sym_out = sym_out;
    out.psd_out = psd_out;
    out.Wproto = Wproto;
    out.Wlegal = Wlegal;
    out.first_col_proto = first_col_proto;
    out.first_col_sym = first_col_sym;
    out.first_col_legal = first_col_legal;
    out.chk_proto = chk_proto;
    out.chk_legal = chk_legal;
    out.summary_table = summary_table;
    out.firstcol_before_table = firstcol_before_table;
    out.firstcol_after_table = firstcol_after_table;
    out.mode_table = mode_table;
    out.files = struct();
    out.files.log_file = log_file;

    % ------------------------------------------------------------
    % Save tables
    % ------------------------------------------------------------
    if cfg.stage10B1.write_csv
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10B1_bcirclegal_summary_%s_%s.csv', run_tag, timestamp));
        firstcol_before_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10B1_firstcol_before_%s_%s.csv', run_tag, timestamp));
        firstcol_after_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10B1_firstcol_after_%s_%s.csv', run_tag, timestamp));
        mode_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10B1_mode_table_%s_%s.csv', run_tag, timestamp));

        writetable(summary_table, summary_csv);
        writetable(firstcol_before_table, firstcol_before_csv);
        writetable(firstcol_after_table, firstcol_after_csv);
        writetable(mode_table, mode_csv);

        out.files.summary_csv = summary_csv;
        out.files.firstcol_before_csv = firstcol_before_csv;
        out.files.firstcol_after_csv = firstcol_after_csv;
        out.files.mode_csv = mode_csv;

        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'First-column before CSV saved to: %s', firstcol_before_csv);
        log_msg(log_fid, 'INFO', 'First-column after CSV saved to: %s', firstcol_after_csv);
        log_msg(log_fid, 'INFO', 'Mode CSV saved to: %s', mode_csv);
    end

    % ------------------------------------------------------------
    % Plot
    % ------------------------------------------------------------
    if cfg.stage10B1.make_plot
        fig_png = fullfile(cfg.paths.figs, ...
            sprintf('stage10B1_bcirclegal_structure_%s_%s.png', run_tag, timestamp));
        fig = plot_stage10B1_legalization(summary_table, firstcol_before_table, firstcol_after_table, mode_table, fig_png);
        out.files.fig_png = fig_png;
        out.fig = fig;
        log_msg(log_fid, 'INFO', 'Figure saved to: %s', fig_png);
    end

    % ------------------------------------------------------------
    % Cache
    % ------------------------------------------------------------
    if cfg.stage10B1.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10B1_bcirclegal_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.B.1 bcirc legalization finished.');

    fprintf('\n');
    fprintf('========== Stage10.B.1 bcirc legalization ==========\n');
    disp(summary_table);
    disp(firstcol_before_table);
    disp(firstcol_after_table);
    disp(mode_table);
    if isfield(out.files, 'summary_csv')
        fprintf('Summary CSV       : %s\n', out.files.summary_csv);
    end
    if isfield(out.files, 'firstcol_before_csv')
        fprintf('FirstCol Before   : %s\n', out.files.firstcol_before_csv);
    end
    if isfield(out.files, 'firstcol_after_csv')
        fprintf('FirstCol After    : %s\n', out.files.firstcol_after_csv);
    end
    if isfield(out.files, 'mode_csv')
        fprintf('Mode CSV          : %s\n', out.files.mode_csv);
    end
    if isfield(out.files, 'fig_png')
        fprintf('Figure            : %s\n', out.files.fig_png);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache             : %s\n', out.files.cache_file);
    end
    fprintf('Log               : %s\n', out.files.log_file);
    fprintf('====================================================\n');
end


function T = local_firstcol_table(first_col_blocks)
    P = size(first_col_blocks, 3);
    trace_block = zeros(P,1);
    fro_block = zeros(P,1);
    lambda_min_block = zeros(P,1);
    for ell = 1:P
        B = first_col_blocks(:,:,ell);
        trace_block(ell) = trace(B);
        fro_block(ell) = norm(B, 'fro');
        lambda_min_block(ell) = min(real(eig(0.5*(B+B.'))));
    end
    T = table( ...
        (0:P-1).', trace_block, fro_block, lambda_min_block, ...
        'VariableNames', {'lag_index','trace_block','fro_block','lambda_min_block'});
end


function fcb = reconstructable_firstcol(first_col_blocks)
    % helper for readability
    fcb = first_col_blocks;
end


function value = local_safe_get(s, field_name, default_value)
    if isfield(s, field_name)
        value = s.(field_name);
    else
        value = default_value;
    end
end
