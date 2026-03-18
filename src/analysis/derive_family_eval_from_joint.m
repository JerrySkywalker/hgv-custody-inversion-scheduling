function out = derive_family_eval_from_joint(joint_eval, family_name, cfg)
%DERIVE_FAMILY_EVAL_FROM_JOINT Derive nominal/heading/critical results from one joint truth evaluation.

if nargin < 2 || isempty(family_name)
    family_name = 'joint';
end
if nargin < 3 || isempty(cfg)
    cfg = joint_eval.cfg;
end

family_name = string(family_name);
if family_name == "joint"
    out = joint_eval;
    return;
end

allowed = ["nominal", "heading", "critical"];
if ~any(family_name == allowed)
    error('Unsupported family_name: %s', family_name);
end

joint_cfg = stage09_prepare_cfg(cfg);
result_cell = cell(numel(joint_eval.result_bank), 1);
for idx = 1:numel(joint_eval.result_bank)
    result_cell{idx} = local_derive_single_result(joint_eval.result_bank(idx), family_name, joint_cfg);
end
result_bank = vertcat(result_cell{:});

S = summarize_stage09_grid(result_bank, joint_cfg);
full_theta_table = local_attach_design_pool_metadata(local_normalize_theta_table(S.full_theta_table), joint_eval.design_pool_table);
feasible_theta_table = local_attach_design_pool_metadata(local_normalize_theta_table(S.feasible_theta_table), joint_eval.design_pool_table);
infeasible_theta_table = local_attach_design_pool_metadata(local_normalize_theta_table(S.infeasible_theta_table), joint_eval.design_pool_table);

casebank = local_filter_casebank(joint_eval.casebank, family_name);

out = struct();
out.cfg = joint_cfg;
out.family_name = family_name;
out.design_pool_table = joint_eval.design_pool_table;
out.full_theta_table = full_theta_table;
out.feasible_theta_table = feasible_theta_table;
out.infeasible_theta_table = infeasible_theta_table;
out.fail_partition_table = S.fail_partition_table;
out.summary_table = S.summary_table;
out.summary = local_build_summary(family_name, full_theta_table, feasible_theta_table, casebank, joint_cfg);
out.casebank = casebank;
out.result_bank = result_bank;
end

function result = local_derive_single_result(joint_result, family_name, cfg)
mask = string(joint_result.case_table.family) == family_name;
case_table = joint_result.case_table(mask, :);
metrics = aggregate_stage09_case_table(case_table, local_row_from_walker(joint_result.walker), cfg, false, height(case_table), height(case_table));

result = joint_result;
result.case_table = case_table;
if isfield(joint_result, 'case_window_bank')
    result.case_window_bank = joint_result.case_window_bank(mask);
end
result.DG_rob = metrics.DG_rob;
result.DA_rob = metrics.DA_rob;
result.DT_bar_rob = metrics.DT_bar_rob;
result.DT_rob = metrics.DT_rob;
result.joint_margin = metrics.joint_margin;
result.pass_ratio = metrics.pass_ratio;
result.feasible_flag = metrics.feasible_flag;
result.dominant_fail_tag = metrics.dominant_fail_tag;
result.worst_case_id_DG = metrics.worst_case_id_DG;
result.worst_case_id_DA = metrics.worst_case_id_DA;
result.worst_case_id_DT = metrics.worst_case_id_DT;
result.rank_score = metrics.rank_score;
result.n_case_total = metrics.n_case_total;
result.n_case_evaluated = metrics.n_case_evaluated;
result.failed_early = false;
end

function row = local_row_from_walker(walker)
row = struct();
row.h_km = walker.h_km;
row.i_deg = walker.i_deg;
row.P = walker.P;
row.T = walker.T;
row.F = walker.F;
row.Ns = walker.P * walker.T;
end

function trajs_out = local_filter_casebank(trajs_in, family_name)
if isempty(trajs_in)
    trajs_out = trajs_in;
    return;
end
mask = false(numel(trajs_in), 1);
for k = 1:numel(trajs_in)
    mask(k) = isfield(trajs_in(k).case, 'family') && string(trajs_in(k).case.family) == family_name;
end
trajs_out = trajs_in(mask);
end

function T = local_normalize_theta_table(T)
if isempty(T)
    return;
end
if ~ismember('DG_worst', T.Properties.VariableNames) && ismember('DG_rob', T.Properties.VariableNames)
    T.DG_worst = T.DG_rob;
end
if ~ismember('DA_worst', T.Properties.VariableNames) && ismember('DA_rob', T.Properties.VariableNames)
    T.DA_worst = T.DA_rob;
end
if ~ismember('DT_bar_worst', T.Properties.VariableNames) && ismember('DT_bar_rob', T.Properties.VariableNames)
    T.DT_bar_worst = T.DT_bar_rob;
end
if ~ismember('DT_worst', T.Properties.VariableNames) && ismember('DT_rob', T.Properties.VariableNames)
    T.DT_worst = T.DT_rob;
end
if ~ismember('feasible_flag', T.Properties.VariableNames) && ismember('joint_feasible', T.Properties.VariableNames)
    T.feasible_flag = T.joint_feasible;
end
end

function summary = local_build_summary(family_name, full_theta_table, feasible_theta_table, trajs_in, cfg_stage)
num_total = height(full_theta_table);
num_feasible = height(feasible_theta_table);
feasible_ratio = 0;
if num_total > 0
    feasible_ratio = num_feasible / num_total;
end

Ns_min_feasible = NaN;
best_joint_margin = NaN;
if num_feasible > 0
    Ns_min_feasible = min(feasible_theta_table.Ns);
    best_joint_margin = max(feasible_theta_table.joint_margin);
end

summary = struct();
summary.family_name = family_name;
summary.num_total = num_total;
summary.num_feasible = num_feasible;
summary.feasible_ratio = feasible_ratio;
summary.Ns_min_feasible = Ns_min_feasible;
summary.best_joint_margin = best_joint_margin;
summary.casebank_size = numel(trajs_in);
summary.config_signature = sprintf('family=%s|derived_from_joint=true|heading_subset_max=%g', ...
    char(family_name), cfg_stage.stage09.casebank_heading_subset_max);
end

function T = local_attach_design_pool_metadata(T, design_pool_table)
if isempty(T) || isempty(design_pool_table)
    return;
end

meta_vars = intersect({'slice_source', 'support_sources', 'num_support_sources'}, design_pool_table.Properties.VariableNames, 'stable');
if isempty(meta_vars)
    return;
end

keys = {'h_km', 'i_deg', 'P', 'T', 'F'};
[tf, loc] = ismember(T(:, keys), design_pool_table(:, keys), 'rows');
for idx = 1:numel(meta_vars)
    if isstring(design_pool_table.(meta_vars{idx}))
        values = strings(height(T), 1);
    elseif isnumeric(design_pool_table.(meta_vars{idx}))
        values = nan(height(T), 1);
    else
        values = repmat(missing, height(T), 1);
    end
    values(tf) = design_pool_table.(meta_vars{idx})(loc(tf));
    T.(meta_vars{idx}) = values;
end
end
