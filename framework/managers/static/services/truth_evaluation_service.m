function truth_result = truth_evaluation_service(cfg, design_pool, task_family)
if nargin < 3
    error('truth_evaluation_service:InvalidInput', ...
        'cfg, design_pool, and task_family are required.');
end

rows = design_pool.design_table;
n = numel(rows);

eval_rows = repmat(struct(), n, 1);

for k = 1:n
    eval_rows(k) = adapter_design_eval_legacy(rows(k), task_family, cfg.profile);
end

truth_table = struct2table(eval_rows);

truth_result = struct();
truth_result.rows = eval_rows;
truth_result.table = truth_table;
truth_result.row_count = n;
truth_result.meta = struct('status', 'multi_design');
end
