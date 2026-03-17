function out = stage10E_screening_acceleration(cfg)
%STAGE10E_SCREENING_ACCELERATION
% Stage10.E:
%   Benchmark a small-grid screening strategy:
%     truth full vs zero-mode vs two-stage vs bcirc-only.
%
% This stage is not yet a runtime speed benchmark. It is a
% decision-quality benchmark on a small theta grid.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10E_prepare_cfg(cfg);
    cfg.project_stage = 'stage10E_screening_acceleration';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage10E.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10E_screening_acceleration_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.E screening benchmark started.');

    [scan_table, detail_list] = run_stage10E_small_grid_scan(cfg);
    [summary_table, confusion_table] = compare_stage10E_screening_vs_truth(scan_table, cfg);

    out = struct();
    out.cfg = cfg;
    out.scan_table = scan_table;
    out.summary_table = summary_table;
    out.confusion_table = confusion_table;
    out.detail_list = detail_list;
    out.files = struct();
    out.files.log_file = log_file;

    if cfg.stage10E.write_csv
        scan_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10E_screen_scan_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10E_screen_summary_%s_%s.csv', run_tag, timestamp));
        confusion_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10E_screen_confusion_%s_%s.csv', run_tag, timestamp));

        writetable(scan_table, scan_csv);
        writetable(summary_table, summary_csv);
        writetable(confusion_table, confusion_csv);

        out.files.scan_csv = scan_csv;
        out.files.summary_csv = summary_csv;
        out.files.confusion_csv = confusion_csv;

        log_msg(log_fid, 'INFO', 'Scan CSV saved to: %s', scan_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Confusion CSV saved to: %s', confusion_csv);
    end

    if cfg.stage10E.make_plot
        fig_png = fullfile(cfg.paths.figs, ...
            sprintf('stage10E_screen_structure_%s_%s.png', run_tag, timestamp));
        fig = plot_stage10E_screening_benchmark(scan_table, confusion_table, summary_table, fig_png);
        out.files.fig_png = fig_png;
        out.fig = fig;
        log_msg(log_fid, 'INFO', 'Figure saved to: %s', fig_png);
    end

    if cfg.stage10E.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10E_screen_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.E screening benchmark finished.');

    fprintf('\n');
    fprintf('========== Stage10.E screening benchmark ==========\n');
    disp(summary_table);
    disp(confusion_table);
    disp(scan_table(1:min(12,height(scan_table)), :));
    if isfield(out.files, 'scan_csv')
        fprintf('Scan CSV      : %s\n', out.files.scan_csv);
    end
    if isfield(out.files, 'summary_csv')
        fprintf('Summary CSV   : %s\n', out.files.summary_csv);
    end
    if isfield(out.files, 'confusion_csv')
        fprintf('Confusion CSV : %s\n', out.files.confusion_csv);
    end
    if isfield(out.files, 'fig_png')
        fprintf('Figure        : %s\n', out.files.fig_png);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache         : %s\n', out.files.cache_file);
    end
    fprintf('Log           : %s\n', out.files.log_file);
    fprintf('===================================================\n');
end
