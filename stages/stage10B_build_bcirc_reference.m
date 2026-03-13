function out = stage10B_build_bcirc_reference(cfg)
%STAGE10B_BUILD_BCIRC_REFERENCE
% Stage10.B:
%   Build a first workable block-circulant reference W_{r,0} from
%   Stage10.A truth-side lag structure.
%
% Main outputs:
%   - first-column blocks
%   - reconstructed bcirc matrix W_{r,0}
%   - truth-side reduced lag matrix
%   - consistency diagnostics
%
% IMPORTANT:
%   This stage is not yet FFT mode decomposition.
%   It prepares the proper object for Stage10.C.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10B_prepare_cfg(cfg);
    cfg.project_stage = 'stage10B_build_bcirc_reference';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage10B.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10B_build_bcirc_reference_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.B bcirc reference construction started.');

    % ------------------------------------------------------------
    % Reuse Stage10.A truth-side extraction
    % ------------------------------------------------------------
    cfgA = cfg;
    cfgA.stage10A.run_tag = [run_tag '_A'];
    cfgA.stage10A.case_source = cfg.stage10B.case_source;
    cfgA.stage10A.theta_source = cfg.stage10B.theta_source;
    cfgA.stage10A.manual_theta = cfg.stage10B.manual_theta;
    cfgA.stage10A.case_index = cfg.stage10B.case_index;
    cfgA.stage10A.window_index = cfg.stage10B.window_index;
    cfgA.stage10A.clip_case_index = cfg.stage10B.clip_case_index;
    cfgA.stage10A.clip_window_index = cfg.stage10B.clip_window_index;
    cfgA.stage10A.anchor_mode = cfg.stage10B.anchor_mode;
    cfgA.stage10A.manual_anchor_plane = cfg.stage10B.manual_anchor_plane;
    cfgA.stage10A.make_plot = false;
    cfgA.stage10A.write_csv = false;
    cfgA.stage10A.save_mat_cache = false;

    outA = stage10A_truth_structure_diagnostics(cfgA);

    lag_pack = outA.lag_pack;

    % ------------------------------------------------------------
    % Build first-column blocks for W_{r,0}
    % ------------------------------------------------------------
    bcirc_pack = group_average_to_bcirc_stage10B(lag_pack, cfg);

    first_col_blocks = bcirc_pack.first_col_blocks_3x3xP;
    Wbcirc = reconstruct_bcirc_matrix_stage10B(first_col_blocks, cfg);

    % Truth-side reduced reference blocks for comparison
    switch lower(string(cfg.stage10B.truth_reduced_source))
        case "active_anchor_mean"
            truth_blocks = lag_pack.lag_blocks_active_mean;
        case "anchor_relative"
            truth_blocks = lag_pack.lag_blocks_ref;
        otherwise
            error('Unknown truth_reduced_source: %s', string(cfg.stage10B.truth_reduced_source));
    end

    chk = check_bcirc_consistency_stage10B(Wbcirc, first_col_blocks, truth_blocks, cfg);

    % ------------------------------------------------------------
    % Compact first-column table
    % ------------------------------------------------------------
    P = size(first_col_blocks, 3);
    trace_firstcol = zeros(P,1);
    fro_firstcol = zeros(P,1);
    lambda_min_firstcol = zeros(P,1);
    for ell = 1:P
        B = first_col_blocks(:,:,ell);
        trace_firstcol(ell) = trace(B);
        fro_firstcol(ell) = norm(B, 'fro');
        lambda_min_firstcol(ell) = min(real(eig(0.5*(B+B.'))));
    end

    firstcol_table = table( ...
        (0:P-1).', trace_firstcol, fro_firstcol, lambda_min_firstcol, ...
        'VariableNames', {'lag_index','trace_block','fro_block','lambda_min_block'});

    summary_table = table( ...
        string(outA.case.case_id), ...
        string(local_safe_get(outA.case, 'family', "")), ...
        outA.theta_row.h_km, outA.theta_row.i_deg, outA.theta_row.P, outA.theta_row.T, outA.theta_row.F, outA.theta_row.Ns, ...
        outA.window_index, outA.window_info.t0_s, outA.window_info.t1_s, ...
        outA.summary_table.lambda_full_eff(1), ...
        outA.summary_table.n_active_plane(1), ...
        outA.summary_table.active_ratio(1), ...
        outA.summary_table.lag_profile_gap_l1(1), ...
        outA.summary_table.lag_profile_gap_l2(1), ...
        chk.lambda_min_truth_reduced, ...
        chk.lambda_min_bcirc, ...
        chk.self_firstcol_err_fro, ...
        chk.bcirc_vs_truth_reduced_fro, ...
        chk.bcirc_vs_truth_reduced_2, ...
        'VariableNames', { ...
            'case_id','family', ...
            'h_km','i_deg','P_theta','T_theta','F_theta','Ns_theta', ...
            'window_index','t0_s','t1_s', ...
            'lambda_full_eff', ...
            'n_active_plane','active_ratio', ...
            'lag_profile_gap_l1','lag_profile_gap_l2', ...
            'lambda_min_truth_reduced','lambda_min_bcirc', ...
            'self_firstcol_err_fro', ...
            'bcirc_vs_truth_reduced_fro', ...
            'bcirc_vs_truth_reduced_2'});

    out = struct();
    out.cfg = cfg;
    out.outA = outA;
    out.bcirc_pack = bcirc_pack;
    out.Wbcirc = Wbcirc;
    out.truth_blocks = truth_blocks;
    out.chk = chk;
    out.summary_table = summary_table;
    out.firstcol_table = firstcol_table;
    out.files = struct();
    out.files.log_file = log_file;

    % ------------------------------------------------------------
    % Save tables
    % ------------------------------------------------------------
    if cfg.stage10B.write_csv
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10B_bcircref_summary_%s_%s.csv', run_tag, timestamp));
        firstcol_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10B_bcircref_firstcol_%s_%s.csv', run_tag, timestamp));

        writetable(summary_table, summary_csv);
        writetable(firstcol_table, firstcol_csv);

        out.files.summary_csv = summary_csv;
        out.files.firstcol_csv = firstcol_csv;

        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'First-column CSV saved to: %s', firstcol_csv);
    end

    % ------------------------------------------------------------
    % Plot
    % ------------------------------------------------------------
    if cfg.stage10B.make_plot
        fig_png = fullfile(cfg.paths.figs, ...
            sprintf('stage10B_bcircref_structure_%s_%s.png', run_tag, timestamp));
        fig = local_plot_bcircref(summary_table, firstcol_table, outA.lag_table, fig_png);
        out.files.fig_png = fig_png;
        out.fig = fig;
        log_msg(log_fid, 'INFO', 'Figure saved to: %s', fig_png);
    end

    % ------------------------------------------------------------
    % Cache
    % ------------------------------------------------------------
    if cfg.stage10B.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10B_bcircref_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.B bcirc reference construction finished.');

    fprintf('\n');
    fprintf('========== Stage10.B bcirc reference construction ==========\n');
    disp(summary_table);
    disp(firstcol_table);
    if isfield(out.files, 'summary_csv')
        fprintf('Summary CSV  : %s\n', out.files.summary_csv);
    end
    if isfield(out.files, 'firstcol_csv')
        fprintf('FirstCol CSV : %s\n', out.files.firstcol_csv);
    end
    if isfield(out.files, 'fig_png')
        fprintf('Figure       : %s\n', out.files.fig_png);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache        : %s\n', out.files.cache_file);
    end
    fprintf('Log          : %s\n', out.files.log_file);
    fprintf('============================================================\n');
end


function fig = local_plot_bcircref(summary_table, firstcol_table, lag_table, out_png_path)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1180 820]);
    tl = tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');

    nexttile;
    b = bar(firstcol_table.lag_index, firstcol_table.trace_block);
    b.FaceColor = [0.25 0.45 0.85];
    xlabel('Lag index');
    ylabel('trace(B_{lag})');
    title('bcirc first-column trace');
    grid on;

    nexttile;
    plot(lag_table.lag_index, lag_table.lag_trace_ref, '-o', 'LineWidth', 1.5, ...
        'MarkerSize', 5, 'Color', [0.15 0.15 0.7]);
    hold on;
    plot(lag_table.lag_index, lag_table.lag_trace_active_mean, '--s', 'LineWidth', 1.5, ...
        'MarkerSize', 5, 'Color', [0.85 0.25 0.25]);
    plot(firstcol_table.lag_index, firstcol_table.trace_block, ':d', 'LineWidth', 1.5, ...
        'MarkerSize', 5, 'Color', [0.15 0.6 0.15]);
    hold off;
    xlabel('Lag index');
    ylabel('trace block');
    title('truth lag profile vs bcirc first-column');
    legend({'anchor-relative truth', 'active-anchor mean', 'bcirc first-column'}, 'Location', 'best');
    grid on;

    nexttile;
    b = bar(firstcol_table.lag_index, firstcol_table.lambda_min_block);
    b.FaceColor = [0.75 0.45 0.2];
    xlabel('Lag index');
    ylabel('min eig of block');
    title('first-column block min eigenvalues');
    grid on;

    nexttile;
    txt = {
        sprintf('lambda_full_eff            = %.6g', summary_table.lambda_full_eff)
        sprintf('lambda_min_truth_reduced   = %.6g', summary_table.lambda_min_truth_reduced)
        sprintf('lambda_min_bcirc           = %.6g', summary_table.lambda_min_bcirc)
        sprintf('self_firstcol_err_fro      = %.6g', summary_table.self_firstcol_err_fro)
        sprintf('bcirc_vs_truth_reduced_fro= %.6g', summary_table.bcirc_vs_truth_reduced_fro)
        sprintf('bcirc_vs_truth_reduced_2  = %.6g', summary_table.bcirc_vs_truth_reduced_2)
        sprintf('n_active_plane            = %d', summary_table.n_active_plane)
        sprintf('active_ratio              = %.3f', summary_table.active_ratio)
        sprintf('lag_profile_gap_l1        = %.3f', summary_table.lag_profile_gap_l1)
        sprintf('lag_profile_gap_l2        = %.3f', summary_table.lag_profile_gap_l2)
        };
    axis off;
    text(0.02, 0.98, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontName', 'Consolas', 'FontSize', 11);
    title('bcirc summary');

    title(tl, 'Stage10.B bcirc reference construction');

    if nargin >= 4 && ~isempty(out_png_path)
        ensure_dir(fileparts(out_png_path));
        exportgraphics(fig, out_png_path, 'Resolution', 200);
    end
end


function value = local_safe_get(s, field_name, default_value)
    if isfield(s, field_name)
        value = s.(field_name);
    else
        value = default_value;
    end
end