function summary_table = stage11_summarize_input_dataset(input_source, cfg)
%STAGE11_SUMMARIZE_INPUT_DATASET Build a compact summary for Stage11.A/B.

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    if isfield(input_source, 'input_dataset')
        input_dataset = input_source.input_dataset;
    else
        input_dataset = input_source;
    end

    n_window = height(input_dataset.window_table);
    n_case = height(input_dataset.case_table);
    n_theta = numel(unique(input_dataset.case_table.theta_id));

    summary_table = table( ...
        string(cfg.stage11.source_stage10_entry), ...
        string(cfg.stage11.partition_mode), ...
        n_theta, n_case, n_window, ...
        'VariableNames', {'source_stage10_entry', 'partition_mode', 'n_theta', 'n_case', 'n_window'});

    if isfield(input_source, 'weak_table') && ~isempty(input_source.weak_table)
        weak_table = input_source.weak_table;
        summary_table.n_weak_valid = sum(weak_table.weak_valid);
        summary_table.mean_eps_pi = mean(weak_table.eps_pi);
        summary_table.mean_L_weak = mean(weak_table.L_weak);
    end
    if isfield(input_source, 'sub_table') && ~isempty(input_source.sub_table)
        summary_table.n_sub_valid = sum(input_source.sub_table.sub_valid);
        summary_table.mean_L_sub = mean(input_source.sub_table.L_sub);
    end
    if isfield(input_source, 'blk_table') && ~isempty(input_source.blk_table)
        summary_table.n_partblk_valid = sum(input_source.blk_table.partblk_valid);
        summary_table.mean_L_partblk = mean(input_source.blk_table.L_partblk);
    end
    if isfield(input_source, 'joint_table') && ~isempty(input_source.joint_table)
        summary_table.n_new_valid = sum(input_source.joint_table.new_valid);
        summary_table.mean_L_new = mean(input_source.joint_table.L_new);
    end
end
