function out = evaluate_design_pool_with_stage05_semantics(cfg, design_pool_table, family_name, semantic_inputs, options)
%EVALUATE_DESIGN_POOL_WITH_STAGE05_SEMANTICS Evaluate an explicit design pool with Stage05 semantics.

mb_safe_startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
end
if nargin < 2 || ~istable(design_pool_table)
    error('evaluate_design_pool_with_stage05_semantics requires cfg and design_pool_table.');
end
if nargin < 3 || isempty(family_name)
    family_name = 'nominal';
end
if nargin < 4 || ~isstruct(semantic_inputs) || ~isfield(semantic_inputs, 'family_inputs')
    error('evaluate_design_pool_with_stage05_semantics requires semantic_inputs from run_mb_legacydg_semantics.');
end
if nargin < 5 || isempty(options)
    options = struct();
end

family_token = lower(strtrim(char(string(family_name))));
if ~isfield(semantic_inputs.family_inputs, family_token)
    error('Stage05 semantic inputs do not contain family: %s', family_name);
end

family_inputs = semantic_inputs.family_inputs.(family_token);
cfg_stage = semantic_inputs.cfg;
if isfield(options, 'use_parallel')
    cfg_stage.stage05.use_parallel = logical(options.use_parallel);
end
gamma_req = semantic_inputs.gamma_req;
parallel_policy = resolve_mb_parallel_policy(local_getfield_or(options, 'parallel_policy', struct('parallel_policy', 'off')));

design_pool_table = local_prepare_design_pool_table(design_pool_table);
if logical(parallel_policy.inner_enabled) && height(design_pool_table) > 1
    partitions = partition_mb_design_tasks(design_pool_table, parallel_policy);
    partition_outputs = run_mb_design_partition_parallel(partitions, ...
        @(partition_table) local_evaluate_partition(partition_table, family_inputs, cfg_stage, gamma_req, false, options), ...
        parallel_policy);
    eval_parts = cellfun(@(s) s.eval_table, partition_outputs, 'UniformOutput', false);
    eval_table = vertcat(eval_parts{:});
else
    eval_table = local_evaluate_partition(design_pool_table, family_inputs, cfg_stage, gamma_req, ...
        logical(local_getfield_or(options, 'use_parallel', true)), options).eval_table;
end

feasible_table = eval_table(eval_table.feasible_flag, :);
n_theta = height(eval_table);

out = struct();
out.cfg = cfg_stage;
out.family_name = string(family_token);
out.design_pool_table = design_pool_table;
out.eval_table = eval_table;
out.feasible_table = feasible_table;
out.summary = struct( ...
    'family_name', string(family_token), ...
    'sensor_group', string(local_getfield_or(options, 'sensor_group', "")), ...
    'num_total', n_theta, ...
    'num_feasible', height(feasible_table), ...
    'feasible_ratio', local_safe_divide(height(feasible_table), n_theta), ...
    'minimum_feasible_Ns', local_min_or_missing(feasible_table, 'Ns'), ...
    'best_D_G_min', local_max_or_nan(feasible_table, 'D_G_min'), ...
    'gamma_req', gamma_req, ...
    'source_stage', "Stage05");
end

function summary = local_eval_one(row, family_inputs, cfg_stage, gamma_req)
res = evaluate_single_layer_walker_stage05(row, family_inputs.trajs_in, gamma_req, cfg_stage, family_inputs.hard_order, family_inputs.eval_context);
summary = struct( ...
    'D_G_min', res.D_G_min, ...
    'D_G_mean', res.D_G_mean, ...
    'pass_ratio', res.pass_ratio, ...
    'feasible_flag', logical(res.feasible_flag), ...
    'n_case_total', res.n_case_total, ...
    'n_case_evaluated', res.n_case_evaluated, ...
    'failed_early', logical(res.failed_early));
end

function partition_out = local_evaluate_partition(partition_table, family_inputs, cfg_stage, gamma_req, use_parallel, options)
row_bank = table2struct(partition_table(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'}));
n_theta = numel(row_bank);

D_G_min = nan(n_theta, 1);
D_G_mean = nan(n_theta, 1);
pass_ratio = nan(n_theta, 1);
feasible_flag = false(n_theta, 1);
n_case_total = nan(n_theta, 1);
n_case_evaluated = nan(n_theta, 1);
failed_early = false(n_theta, 1);

if use_parallel
    parfor idx = 1:n_theta
        summary = local_eval_one(row_bank(idx), family_inputs, cfg_stage, gamma_req);
        D_G_min(idx) = summary.D_G_min;
        D_G_mean(idx) = summary.D_G_mean;
        pass_ratio(idx) = summary.pass_ratio;
        feasible_flag(idx) = summary.feasible_flag;
        n_case_total(idx) = summary.n_case_total;
        n_case_evaluated(idx) = summary.n_case_evaluated;
        failed_early(idx) = summary.failed_early;
    end
else
    for idx = 1:n_theta
        summary = local_eval_one(row_bank(idx), family_inputs, cfg_stage, gamma_req);
        D_G_min(idx) = summary.D_G_min;
        D_G_mean(idx) = summary.D_G_mean;
        pass_ratio(idx) = summary.pass_ratio;
        feasible_flag(idx) = summary.feasible_flag;
        n_case_total(idx) = summary.n_case_total;
        n_case_evaluated(idx) = summary.n_case_evaluated;
        failed_early(idx) = summary.failed_early;
    end
end

eval_table = partition_table;
eval_table.family_name = repmat(string(local_getfield_or(options, 'family_name', "")), n_theta, 1);
eval_table.sensor_group = repmat(string(local_getfield_or(options, 'sensor_group', "")), n_theta, 1);
eval_table.semantic_mode = repmat("legacyDG", n_theta, 1);
eval_table.source_stage = repmat("Stage05", n_theta, 1);
eval_table.pass_ratio = pass_ratio;
eval_table.feasible_flag = feasible_flag;
eval_table.feasible = feasible_flag;
eval_table.D_G_min = D_G_min;
eval_table.D_G_mean = D_G_mean;
eval_table.joint_margin = D_G_min;
eval_table.n_case_total = n_case_total;
eval_table.n_case_evaluated = n_case_evaluated;
eval_table.failed_early = failed_early;

partition_out = struct('eval_table', eval_table);
end

function T = local_prepare_design_pool_table(T)
required = {'h_km', 'i_deg', 'P', 'T', 'F'};
missing = setdiff(required, T.Properties.VariableNames);
if ~isempty(missing)
    error('design_pool_table missing variables: %s', strjoin(missing, ', '));
end
if ~ismember('Ns', T.Properties.VariableNames)
    T.Ns = T.P .* T.T;
end
T = sortrows(T, {'Ns', 'h_km', 'i_deg', 'P', 'T'}, {'ascend', 'ascend', 'ascend', 'ascend', 'ascend'});
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

function value = local_max_or_nan(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
value = max(T.(field_name), [], 'omitnan');
end

function value = local_safe_divide(a, b)
if b == 0
    value = 0;
else
    value = a / b;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
