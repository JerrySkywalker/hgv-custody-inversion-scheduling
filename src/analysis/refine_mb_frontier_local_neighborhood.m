function result = refine_mb_frontier_local_neighborhood(run, search_domain, evaluate_new_fn, aggregate_fn, options)
%REFINE_MB_FRONTIER_LOCAL_NEIGHBORHOOD Refine a weak frontier with bounded local P/T/i probes.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || ~isa(evaluate_new_fn, 'function_handle')
    error('refine_mb_frontier_local_neighborhood requires evaluate_new_fn.');
end
if nargin < 4 || ~isa(aggregate_fn, 'function_handle')
    error('refine_mb_frontier_local_neighborhood requires aggregate_fn.');
end
if nargin < 5 || isempty(options)
    options = struct();
end

mode_name = lower(strtrim(char(string(local_getfield_or(options, 'mode', "off")))));
result = struct('run', run, 'summary_table', local_empty_summary_table(), 'applied', false, 'candidate_design_table', table());
if strcmp(mode_name, 'off')
    result.summary_table(1, :) = local_build_summary_row(run, mode_name, false, false, 0, 0, 0, 0, false, "", "frontier refinement disabled");
    return;
end

plan = build_mb_frontier_candidate_refinement_plan(run, search_domain, options);
frontier_before = local_frontier_stats(local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'frontier_vs_i', table()), local_unique_i_count(run));
if ~plan.weak_frontier_detected || isempty(plan.candidate_designs)
    result.summary_table(1, :) = local_build_summary_row(run, mode_name, true, false, ...
        frontier_before.defined_count, frontier_before.internal_count, 0, 0, false, ...
        string(plan.refinement_scope), string(plan.note));
    return;
end

new_eval = evaluate_new_fn(plan.candidate_designs);
merged_design_table = local_merge_tables(local_getfield_or(run, 'design_table', table()), plan.candidate_designs, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'});
merged_eval_table = local_merge_tables(local_getfield_or(run, 'eval_table', table()), local_getfield_or(new_eval, 'eval_table', table()), {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'});
merged_feasible_table = local_pick_feasible_rows(merged_eval_table);
merged_aggregate = aggregate_fn(merged_eval_table);

frontier_after = local_frontier_stats(local_getfield_or(merged_aggregate, 'frontier_vs_i', table()), local_unique_i_count_from_table(merged_design_table));
merged_aggregate = local_annotate_refinement_provenance(local_getfield_or(run, 'aggregate', struct()), merged_aggregate, plan.candidate_designs);
run.design_table = merged_design_table;
run.eval_table = merged_eval_table;
run.feasible_table = merged_feasible_table;
run.aggregate = merged_aggregate;
run.aggregate.frontier_refinement_plan = plan;
run.aggregate.frontier_refinement_summary = local_build_summary_row(run, mode_name, true, true, ...
    frontier_before.defined_count, frontier_after.defined_count, height(plan.candidate_designs), ...
    max(frontier_after.defined_count - frontier_before.defined_count, 0), logical(plan.budget_hit), ...
    string(plan.refinement_scope), string(plan.note));
run.aggregate.frontier_refinement_summary.frontier_internal_before = frontier_before.internal_count;
run.aggregate.frontier_refinement_summary.frontier_internal_after = frontier_after.internal_count;
run.aggregate.frontier_refinement_summary.coverage_improved = frontier_after.defined_count > frontier_before.defined_count;

run.expansion_state = local_update_effective_domain(local_getfield_or(run, 'expansion_state', struct()), merged_design_table);
result.run = run;
result.summary_table = run.aggregate.frontier_refinement_summary;
result.applied = true;
result.candidate_design_table = plan.candidate_designs;
end

function T = local_empty_summary_table()
T = table('Size', [0, 12], ...
    'VariableTypes', {'double', 'string', 'string', 'logical', 'logical', 'double', 'double', 'double', 'double', 'logical', 'string', 'string'}, ...
    'VariableNames', {'h_km', 'family_name', 'refinement_mode', 'weak_frontier_detected', 'refinement_applied', ...
    'frontier_defined_before', 'frontier_defined_after', 'candidate_design_count', 'new_frontier_points', 'budget_hit', 'refinement_scope', 'note'});
end

function row = local_build_summary_row(run, mode_name, weak_frontier, applied, defined_before, defined_after, candidate_design_count, new_frontier_points, budget_hit, scope, note)
row = table( ...
    local_getfield_or(run, 'h_km', NaN), ...
    string(local_getfield_or(run, 'family_name', "")), ...
    string(mode_name), ...
    logical(weak_frontier), ...
    logical(applied), ...
    double(defined_before), ...
    double(defined_after), ...
    double(candidate_design_count), ...
    double(new_frontier_points), ...
    logical(budget_hit), ...
    string(scope), ...
    string(note), ...
    'VariableNames', {'h_km', 'family_name', 'refinement_mode', 'weak_frontier_detected', 'refinement_applied', ...
    'frontier_defined_before', 'frontier_defined_after', 'candidate_design_count', 'new_frontier_points', 'budget_hit', 'refinement_scope', 'note'});
end

function stats = local_frontier_stats(frontier, sampled_count)
if nargin < 2
    sampled_count = 0;
end
stats = struct('defined_count', 0, 'internal_count', 0, 'sampled_count', sampled_count);
if ~istable(frontier) || isempty(frontier) || ~ismember('minimum_feasible_Ns', frontier.Properties.VariableNames)
    return;
end
frontier = frontier(isfinite(frontier.minimum_feasible_Ns), :);
stats.defined_count = height(frontier);
stats.internal_count = height(frontier);
end

function count = local_unique_i_count(run)
count = local_unique_i_count_from_table(local_getfield_or(run, 'design_table', table()));
end

function count = local_unique_i_count_from_table(design_table)
if isempty(design_table) || ~ismember('i_deg', design_table.Properties.VariableNames)
    count = 0;
else
    count = numel(unique(design_table.i_deg, 'sorted'));
end
end

function aggregate = local_annotate_refinement_provenance(base_aggregate, aggregate, candidate_designs)
aggregate.frontier_vs_i_base = local_getfield_or(base_aggregate, 'frontier_vs_i', table());
aggregate.requirement_surface_iP_base = local_getfield_or(base_aggregate, 'requirement_surface_iP', struct());
surface_table = local_getfield_or(local_getfield_or(aggregate, 'requirement_surface_iP', struct()), 'surface_table', table());
if isempty(surface_table) || isempty(candidate_designs)
    return;
end
candidate_cells = unique(candidate_designs(:, {'h_km', 'i_deg', 'P'}), 'rows', 'stable');
surface_table.frontier_refinement_touched = false(height(surface_table), 1);
surface_table.frontier_refinement_status = repmat("base_search", height(surface_table), 1);
tf_touch = ismember(surface_table(:, {'h_km', 'i_deg', 'P'}), candidate_cells, 'rows');
surface_table.frontier_refinement_touched = tf_touch;
surface_table.frontier_refinement_status(tf_touch) = "frontier_refinement_checked";
aggregate.requirement_surface_iP.surface_table = surface_table;
end

function expansion_state = local_update_effective_domain(expansion_state, design_table)
effective = local_getfield_or(expansion_state, 'effective_search_domain', struct());
if isempty(design_table)
    expansion_state.effective_search_domain = effective;
    return;
end
effective.ns_search_max = max(local_getfield_or(effective, 'ns_search_max', -inf), max(design_table.Ns, [], 'omitnan'));
effective.ns_search_min = min(local_getfield_or(effective, 'ns_search_min', inf), min(design_table.Ns, [], 'omitnan'));
effective.P_grid = unique(design_table.P, 'sorted').';
effective.T_grid = unique(design_table.T, 'sorted').';
effective.inclination_grid_deg = unique(design_table.i_deg, 'sorted').';
expansion_state.effective_search_domain = effective;
end

function feasible_table = local_pick_feasible_rows(eval_table)
if isempty(eval_table)
    feasible_table = eval_table;
elseif ismember('feasible_flag', eval_table.Properties.VariableNames)
    feasible_table = eval_table(logical(eval_table.feasible_flag), :);
elseif ismember('joint_feasible', eval_table.Properties.VariableNames)
    feasible_table = eval_table(logical(eval_table.joint_feasible), :);
else
    feasible_table = eval_table([], :);
end
end

function merged = local_merge_tables(base_table, extra_table, key_vars)
if isempty(base_table)
    merged = extra_table;
    return;
end
if isempty(extra_table)
    merged = base_table;
    return;
end
all_vars = union(base_table.Properties.VariableNames, extra_table.Properties.VariableNames, 'stable');
base_table = local_add_missing_vars(base_table, all_vars, extra_table);
extra_table = local_add_missing_vars(extra_table, all_vars, base_table);
merged = [base_table(:, all_vars); extra_table(:, all_vars)];
if ~isempty(key_vars)
    [~, ia] = unique(merged(:, key_vars), 'rows', 'stable');
    merged = merged(sort(ia), :);
end
end

function T = local_add_missing_vars(T, all_vars, reference)
missing = setdiff(all_vars, T.Properties.VariableNames, 'stable');
for idx = 1:numel(missing)
    name = missing{idx};
    if ismember(name, reference.Properties.VariableNames)
        ref = reference.(name);
        T.(name) = local_default_column_like(ref, height(T));
    else
        T.(name) = strings(height(T), 1);
    end
end
T = T(:, all_vars);
end

function values = local_default_column_like(ref, n)
if isstring(ref)
    values = strings(n, 1);
elseif iscell(ref)
    values = repmat({''}, n, 1);
elseif islogical(ref)
    values = false(n, 1);
elseif isnumeric(ref)
    values = nan(n, 1);
else
    values = strings(n, 1);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
