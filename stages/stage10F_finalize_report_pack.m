function out = stage10F_finalize_report_pack(cfg)
%STAGE10F_FINALIZE_REPORT_PACK
% Stage10.F:
%   Final packaging layer for Stage10.A-E.1
%
% Outputs:
%   - master_table      : representative-sample compact summary
%   - screening_table   : small-grid refined screening summary
%   - one master figure : thesis-ready compact evidence figure

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10F_prepare_cfg(cfg);
    cfg.project_stage = 'stage10F_finalize_report_pack';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage10F.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10F_finalize_report_pack_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.F final report pack started.');

    core = collect_stage10F_core_tables(cfg);
    [master_table, screening_table] = build_stage10F_master_summary(core, cfg);

    out = struct();
    out.cfg = cfg;
    out.core = core;
    out.master_table = master_table;
    out.screening_table = screening_table;
    out.files = struct();
    out.files.log_file = log_file;

    if cfg.stage10F.write_csv
        master_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10F_master_summary_%s_%s.csv', run_tag, timestamp));
        screening_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10F_screening_summary_%s_%s.csv', run_tag, timestamp));

        writetable(master_table, master_csv);
        writetable(screening_table, screening_csv);

        out.files.master_csv = master_csv;
        out.files.screening_csv = screening_csv;

        log_msg(log_fid, 'INFO', 'Master CSV saved to: %s', master_csv);
        log_msg(log_fid, 'INFO', 'Screening CSV saved to: %s', screening_csv);
    end

    if cfg.stage10F.make_plot
        fig_png = fullfile(cfg.paths.figs, ...
            sprintf('stage10F_master_figure_%s_%s.png', run_tag, timestamp));
        fig = plot_stage10F_master_figure(core, master_table, screening_table, fig_png);
        out.files.fig_png = fig_png;
        out.fig = fig;
        log_msg(log_fid, 'INFO', 'Figure saved to: %s', fig_png);
    end

    if cfg.stage10F.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10F_final_pack_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.F final report pack finished.');

    fprintf('\n');
    fprintf('========== Stage10.F final report pack ==========\n');
    disp(master_table);
    disp(screening_table);
    if isfield(out.files, 'master_csv')
        fprintf('Master CSV    : %s\n', out.files.master_csv);
    end
    if isfield(out.files, 'screening_csv')
        fprintf('Screening CSV : %s\n', out.files.screening_csv);
    end
    if isfield(out.files, 'fig_png')
        fprintf('Figure        : %s\n', out.files.fig_png);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache         : %s\n', out.files.cache_file);
    end
    fprintf('Log           : %s\n', out.files.log_file);
    fprintf('=================================================\n');
end