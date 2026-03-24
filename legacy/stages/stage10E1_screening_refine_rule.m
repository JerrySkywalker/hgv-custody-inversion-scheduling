function out = stage10E1_screening_refine_rule(cfg)
%STAGE10E1_SCREENING_REFINE_RULE
% Stage10.E.1:
%   Benchmark refined screening rule:
%       zero-mode = primary gate
%       bcirc-min = warning / refine trigger
%
% This stage reuses Stage10.E small-grid scan values and only changes the
% decision logic.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10E1_prepare_cfg(cfg);
    cfg.project_stage = 'stage10E1_screening_refine_rule';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage10E1.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10E1_screening_refine_rule_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.E.1 refined screening rule benchmark started.');

    % ------------------------------------------------------------
    % Reuse Stage10.E scan values
    % ------------------------------------------------------------
    cfgE = cfg;
    cfgE.stage10E.run_tag = [run_tag '_E'];
    cfgE.stage10E.case_index = cfg.stage10E1.case_index;
    cfgE.stage10E.window_index = cfg.stage10E1.window_index;
    cfgE.stage10E.anchor_mode = cfg.stage10E1.anchor_mode;
    cfgE.stage10E.manual_anchor_plane = cfg.stage10E1.manual_anchor_plane;
    cfgE.stage10E.prototype_source = cfg.stage10E1.prototype_source;

    cfgE.stage10E.grid_h_km = cfg.stage10E1.grid_h_km;
    cfgE.stage10E.grid_i_deg = cfg.stage10E1.grid_i_deg;
    cfgE.stage10E.grid_P = cfg.stage10E1.grid_P;
    cfgE.stage10E.grid_T = cfg.stage10E1.grid_T;
    cfgE.stage10E.grid_F = cfg.stage10E1.grid_F;

    cfgE.stage10E.threshold_truth = cfg.stage10E1.threshold_truth;
    cfgE.stage10E.threshold_zero = cfg.stage10E1.threshold_zero;
    cfgE.stage10E.threshold_bcirc = cfg.stage10E1.threshold_bcirc;

    cfgE.stage10E.make_plot = false;
    cfgE.stage10E.write_csv = false;
    cfgE.stage10E.save_mat_cache = false;

    outE = stage10E_screening_acceleration(cfgE);
    scan_table = outE.scan_table;

    % ------------------------------------------------------------
    % Apply refined rule
    % ------------------------------------------------------------
    scan_table_e1 = classify_stage10E1_screening(scan_table, cfg);
    [summary_table, confusion_table, label_count_table] = summarize_stage10E1_screening(scan_table_e1, cfg);

    out = struct();
    out.cfg = cfg;
    out.outE = outE;
    out.scan_table_e1 = scan_table_e1;
    out.summary_table = summary_table;
    out.confusion_table = confusion_table;
    out.label_count_table = label_count_table;
    out.files = struct();
    out.files.log_file = log_file;

    if cfg.stage10E1.write_csv
        scan_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10E1_screen_scan_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10E1_screen_summary_%s_%s.csv', run_tag, timestamp));
        confusion_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10E1_screen_confusion_%s_%s.csv', run_tag, timestamp));
        label_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10E1_screen_labels_%s_%s.csv', run_tag, timestamp));

        writetable(scan_table_e1, scan_csv);
        writetable(summary_table, summary_csv);
        writetable(confusion_table, confusion_csv);
        writetable(label_count_table, label_csv);

        out.files.scan_csv = scan_csv;
        out.files.summary_csv = summary_csv;
        out.files.confusion_csv = confusion_csv;
        out.files.label_csv = label_csv;

        log_msg(log_fid, 'INFO', 'Scan CSV saved to: %s', scan_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Confusion CSV saved to: %s', confusion_csv);
        log_msg(log_fid, 'INFO', 'Label CSV saved to: %s', label_csv);
    end

    if cfg.stage10E1.make_plot
        fig_png = fullfile(cfg.paths.figs, ...
            sprintf('stage10E1_screen_structure_%s_%s.png', run_tag, timestamp));
        fig = plot_stage10E1_screening(scan_table_e1, confusion_table, label_count_table, summary_table, fig_png);
        out.files.fig_png = fig_png;
        out.fig = fig;
        log_msg(log_fid, 'INFO', 'Figure saved to: %s', fig_png);
    end

    if cfg.stage10E1.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10E1_screen_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.E.1 refined screening rule benchmark finished.');

    fprintf('\n');
    fprintf('========== Stage10.E.1 refined screening rule ==========\n');
    disp(summary_table);
    disp(confusion_table);
    disp(label_count_table);
    disp(scan_table_e1(1:min(12,height(scan_table_e1)), :));
    if isfield(out.files, 'scan_csv')
        fprintf('Scan CSV      : %s\n', out.files.scan_csv);
    end
    if isfield(out.files, 'summary_csv')
        fprintf('Summary CSV   : %s\n', out.files.summary_csv);
    end
    if isfield(out.files, 'confusion_csv')
        fprintf('Confusion CSV : %s\n', out.files.confusion_csv);
    end
    if isfield(out.files, 'label_csv')
        fprintf('Label CSV     : %s\n', out.files.label_csv);
    end
    if isfield(out.files, 'fig_png')
        fprintf('Figure        : %s\n', out.files.fig_png);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache         : %s\n', out.files.cache_file);
    end
    fprintf('Log           : %s\n', out.files.log_file);
    fprintf('========================================================\n');
end
