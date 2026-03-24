function truth_result = truth_evaluation_service(cfg, design_pool, task_family)
if nargin < 3
    error('truth_evaluation_service:InvalidInput', ...
        'cfg, design_pool, and task_family are required.');
end

design_row = design_pool.design_table(1);
task_case = task_family.case_list(1);

design_eval = adapter_design_eval_legacy(design_row, task_case, cfg.profile);

truth_result = struct();
truth_result.rows = design_eval;
truth_result.row_count = 1;
truth_result.meta = struct('status', 'minimal');
end
