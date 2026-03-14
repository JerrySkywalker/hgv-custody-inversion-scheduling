function out = stage11_entry(cfg)
%STAGE11_ENTRY Stage11 orchestrator for tightened geometric certificates.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);
    cfg.project_stage = 'stage11_entry';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage11.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage11_entry_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage11 started.');

    input_dataset = stage11_build_input_dataset(cfg);
    summary_table = stage11_summarize_input_dataset(input_dataset, cfg);

    out = struct();
    out.cfg = cfg;
    out.input_dataset = input_dataset;
    out.window_table = input_dataset.window_table;
    out.case_table = input_dataset.case_table;
    out.summary_table = summary_table;
    out.files = struct();
    out.files.log_file = log_file;

    if cfg.stage11.write_csv
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage11_input_summary_%s_%s.csv', run_tag, timestamp));
        window_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage11_input_windows_%s_%s.csv', run_tag, timestamp));
        case_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage11_input_cases_%s_%s.csv', run_tag, timestamp));

        writetable(summary_table, summary_csv);
        writetable(stage11_make_window_export_table(input_dataset.window_table), window_csv);
        writetable(stage11_make_case_export_table(input_dataset.case_table), case_csv);

        out.files.summary_csv = summary_csv;
        out.files.window_csv = window_csv;
        out.files.case_csv = case_csv;
    end

    if cfg.stage11.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage11_input_dataset_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    end

    log_msg(log_fid, 'INFO', 'Stage11 finished.');
end
