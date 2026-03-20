function incremental = evaluate_design_pool_incremental_over_ns(existing_run, target_design_table, evaluate_new_fn, aggregate_fn, context)
%EVALUATE_DESIGN_POOL_INCREMENTAL_OVER_NS Evaluate only newly added MB designs and merge with cached results.

if nargin < 1 || isempty(existing_run)
    existing_run = struct();
end
if nargin < 2 || ~istable(target_design_table)
    error('evaluate_design_pool_incremental_over_ns requires target_design_table.');
end
if nargin < 3 || ~isa(evaluate_new_fn, 'function_handle')
    error('evaluate_design_pool_incremental_over_ns requires evaluate_new_fn.');
end
if nargin < 4 || ~isa(aggregate_fn, 'function_handle')
    error('evaluate_design_pool_incremental_over_ns requires aggregate_fn.');
end
if nargin < 5 || isempty(context)
    context = struct();
end

key_vars = {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'};
previous_design = local_getfield_or(existing_run, 'design_table', table());
previous_eval = local_getfield_or(existing_run, 'eval_table', table());
previous_feasible = local_getfield_or(existing_run, 'feasible_table', table());
previous_phasecurve = local_getfield_or(local_getfield_or(existing_run, 'aggregate', struct()), 'passratio_phasecurve', table());

if isempty(previous_design)
    added_design_table = target_design_table;
    seed_hit = false;
else
    [is_existing, ~] = ismember(target_design_table(:, key_vars), previous_design(:, key_vars), 'rows');
    added_design_table = target_design_table(~is_existing, :);
    seed_hit = true;
end

if isempty(added_design_table)
    added_eval_table = table();
    added_feasible_table = table();
else
    added_out = evaluate_new_fn(added_design_table);
    added_eval_table = local_getfield_or(added_out, 'eval_table', table());
    added_feasible_table = local_getfield_or(added_out, 'feasible_table', table());
end

merged_design = local_merge_unique(previous_design, target_design_table, key_vars);
merged_eval = local_merge_unique(previous_eval, added_eval_table, key_vars);
merged_feasible = local_filter_feasible(local_merge_unique(previous_feasible, added_feasible_table, key_vars));
aggregate = aggregate_fn(merged_eval);
phasecurve = merge_mb_phasecurve_tables(previous_phasecurve, local_getfield_or(aggregate, 'passratio_phasecurve', table()));

incremental = struct();
incremental.design_table = merged_design;
incremental.eval_table = merged_eval;
incremental.feasible_table = merged_feasible;
incremental.aggregate = aggregate;
incremental.passratio_phasecurve = phasecurve;
incremental.added_design_table = added_design_table;
incremental.added_eval_table = added_eval_table;
incremental.history_row = struct( ...
    'iteration', local_getfield_or(context, 'iteration', 1), ...
    'semantic_mode', string(local_getfield_or(context, 'semantic_mode', "")), ...
    'sensor_group', string(local_getfield_or(context, 'sensor_group', "")), ...
    'family_name', string(local_getfield_or(context, 'family_name', "")), ...
    'height_km', local_getfield_or(context, 'height_km', NaN), ...
    'action', string(local_getfield_or(context, 'action', "")), ...
    'stop_reason', string(local_getfield_or(context, 'stop_reason', "")), ...
    'cache_seed_hit', seed_hit, ...
    'previous_design_count', height(previous_design), ...
    'added_design_count', height(added_design_table), ...
    'merged_design_count', height(merged_design), ...
    'P_grid', reshape(unique(merged_design.P).', 1, []), ...
    'T_grid', reshape(unique(merged_design.T).', 1, []), ...
    'ns_search_min', local_get_ns_bound(merged_design, 'min'), ...
    'ns_search_max', local_get_ns_bound(merged_design, 'max'));
end

function merged = local_merge_unique(base_table, added_table, key_vars)
if isempty(base_table)
    merged = added_table;
    return;
end
if isempty(added_table)
    merged = base_table;
    return;
end
merged = [base_table; added_table];
merged = sortrows(merged, key_vars);
[~, keep_idx] = unique(merged(:, key_vars), 'rows', 'last');
merged = merged(sort(keep_idx), :);
end

function feasible = local_filter_feasible(T)
if isempty(T)
    feasible = T;
    return;
end
if ismember('feasible', T.Properties.VariableNames)
    feasible = T(logical(T.feasible), :);
elseif ismember('feasible_flag', T.Properties.VariableNames)
    feasible = T(logical(T.feasible_flag), :);
elseif ismember('joint_feasible', T.Properties.VariableNames)
    feasible = T(logical(T.joint_feasible), :);
else
    feasible = table();
end
end

function value = local_get_ns_bound(T, mode)
if isempty(T) || ~ismember('Ns', T.Properties.VariableNames)
    value = NaN;
    return;
end
switch lower(mode)
    case 'min'
        value = min(T.Ns);
    otherwise
        value = max(T.Ns);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
