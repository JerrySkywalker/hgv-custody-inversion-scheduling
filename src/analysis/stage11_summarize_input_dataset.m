function summary_table = stage11_summarize_input_dataset(input_dataset, cfg)
%STAGE11_SUMMARIZE_INPUT_DATASET Build a compact summary for Stage11.A/B.

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    n_window = height(input_dataset.window_table);
    n_case = height(input_dataset.case_table);
    n_theta = numel(unique(input_dataset.case_table.theta_id));

    summary_table = table( ...
        string(cfg.stage11.source_stage10_entry), ...
        string(cfg.stage11.partition_mode), ...
        n_theta, n_case, n_window, ...
        'VariableNames', {'source_stage10_entry', 'partition_mode', 'n_theta', 'n_case', 'n_window'});
end
