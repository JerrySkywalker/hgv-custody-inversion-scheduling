function files = stage11_export_tables(out, cfg, timestamp)
%STAGE11_EXPORT_TABLES Export Stage11 core tables.

    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end

    files = struct();

    summary_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage11_summary_%s_%s.csv', cfg.stage11.run_tag, timestamp));
    window_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage11_window_table_%s_%s.csv', cfg.stage11.run_tag, timestamp));
    case_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage11_case_table_%s_%s.csv', cfg.stage11.run_tag, timestamp));

    writetable(out.summary_table, summary_csv);
    writetable(stage11_make_window_export_table(out.window_table), window_csv);
    writetable(stage11_make_case_export_table(out.case_table), case_csv);

    files.summary_csv = summary_csv;
    files.window_csv = window_csv;
    files.case_csv = case_csv;
end
