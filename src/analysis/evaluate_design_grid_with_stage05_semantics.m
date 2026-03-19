function out = evaluate_design_grid_with_stage05_semantics(design_table, semantic_inputs, opts)
%EVALUATE_DESIGN_GRID_WITH_STAGE05_SEMANTICS Evaluate a design grid using the original Stage05 nominal-family semantics.

startup();

if nargin < 2 || isempty(semantic_inputs) || ~isstruct(semantic_inputs)
    error('evaluate_design_grid_with_stage05_semantics requires semantic_inputs from load_mb_stage05_semantic_inputs.');
end
if nargin < 3 || isempty(opts)
    opts = struct();
end

cfg = semantic_inputs.cfg;
trajs_nominal = semantic_inputs.trajs_nominal;
gamma_req = semantic_inputs.gamma_req;
hard_order = semantic_inputs.hard_order;
eval_context = semantic_inputs.eval_context;
use_parallel = local_getfield_or(opts, 'use_parallel', local_getfield_or(semantic_inputs, 'use_parallel', true));

n_design = height(design_table);
rows = table2struct(design_table);

D_G_min = nan(n_design, 1);
D_G_mean = nan(n_design, 1);
pass_ratio = nan(n_design, 1);
feasible_flag = false(n_design, 1);
n_case_total = nan(n_design, 1);
n_case_evaluated = nan(n_design, 1);
failed_early = false(n_design, 1);

if use_parallel
    parfor idx = 1:n_design
        summary = local_eval_one(rows(idx), trajs_nominal, gamma_req, cfg, hard_order, eval_context);
        D_G_min(idx) = summary.D_G_min;
        D_G_mean(idx) = summary.D_G_mean;
        pass_ratio(idx) = summary.pass_ratio;
        feasible_flag(idx) = summary.feasible_flag;
        n_case_total(idx) = summary.n_case_total;
        n_case_evaluated(idx) = summary.n_case_evaluated;
        failed_early(idx) = summary.failed_early;
    end
else
    for idx = 1:n_design
        summary = local_eval_one(rows(idx), trajs_nominal, gamma_req, cfg, hard_order, eval_context);
        D_G_min(idx) = summary.D_G_min;
        D_G_mean(idx) = summary.D_G_mean;
        pass_ratio(idx) = summary.pass_ratio;
        feasible_flag(idx) = summary.feasible_flag;
        n_case_total(idx) = summary.n_case_total;
        n_case_evaluated(idx) = summary.n_case_evaluated;
        failed_early(idx) = summary.failed_early;
    end
end

eval_table = design_table;
eval_table.family_name = repmat("nominal", n_design, 1);
eval_table.D_G_min = D_G_min;
eval_table.D_G_mean = D_G_mean;
eval_table.pass_ratio = pass_ratio;
eval_table.feasible = feasible_flag;
eval_table.n_case_total = n_case_total;
eval_table.n_case_evaluated = n_case_evaluated;
eval_table.failed_early = failed_early;

feasible_table = eval_table(eval_table.feasible, :);

out = struct();
out.eval_table = eval_table;
out.feasible_table = feasible_table;
out.summary = struct( ...
    'design_count', n_design, ...
    'feasible_count', height(feasible_table), ...
    'minimum_feasible_Ns', local_min_or_missing(feasible_table, 'Ns'), ...
    'gamma_req', gamma_req);
end

function summary = local_eval_one(row, trajs_nominal, gamma_req, cfg, hard_order, eval_context)
res = evaluate_single_layer_walker_stage05(row, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
summary = struct( ...
    'D_G_min', res.D_G_min, ...
    'D_G_mean', res.D_G_mean, ...
    'pass_ratio', res.pass_ratio, ...
    'feasible_flag', logical(res.feasible_flag), ...
    'n_case_total', res.n_case_total, ...
    'n_case_evaluated', res.n_case_evaluated, ...
    'failed_early', logical(res.failed_early));
end

function value = local_min_or_missing(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = missing;
    return;
end
value = min(T.(field_name), [], 'omitnan');
if ~isfinite(value)
    value = missing;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
