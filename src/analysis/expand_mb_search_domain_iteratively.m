function expansion = expand_mb_search_domain_iteratively(search_domain_in, build_design_table_fn, evaluate_domain_fn, options)
%EXPAND_MB_SEARCH_DOMAIN_ITERATIVELY Iteratively expand an MB search domain over Ns-target blocks.

if nargin < 1 || isempty(search_domain_in)
    search_domain_in = struct();
end
if nargin < 2 || ~isa(build_design_table_fn, 'function_handle')
    error('expand_mb_search_domain_iteratively requires build_design_table_fn.');
end
if nargin < 3 || ~isa(evaluate_domain_fn, 'function_handle')
    error('expand_mb_search_domain_iteratively requires evaluate_domain_fn.');
end
if nargin < 4 || isempty(options)
    options = struct();
end

current_domain = local_normalize_search_domain(search_domain_in);
history_rows = repmat(local_empty_history_row(), 0, 1);
cache_records = repmat(struct('cache_file', "", 'manifest_csv', "", 'cache_hit', false, 'reason', "", 'family_name', "", 'h_km', NaN), 0, 1);
elapsed_start = tic;
iteration = 0;
last_action = "initial_domain";
last_action_reason = "Seed the expansion loop with the configured initial search domain.";
last_improvement_iteration = 0;
best_metrics = struct('max_passratio', -inf, 'frontier_points', -inf, 'internal_cells', -inf);

while true
    iteration = iteration + 1;
    design_table = build_design_table_fn(current_domain, iteration);
    eval_output = evaluate_domain_fn(current_domain, design_table, iteration, last_action, last_action_reason);
    run = local_getfield_or(eval_output, 'run', struct());
    cache_record = local_getfield_or(eval_output, 'cache_record', struct('cache_hit', false));
    diag = local_build_iteration_diagnostics(run, current_domain, options);

    history_row = local_empty_history_row();
    history_row.iteration = iteration;
    history_row.semantic_mode = string(local_getfield_or(options, 'semantic_mode', ""));
    history_row.sensor_group = string(local_getfield_or(options, 'sensor_group', ""));
    history_row.family_name = string(local_getfield_or(options, 'family_name', ""));
    history_row.height_km = local_getfield_or(options, 'height_km', NaN);
    history_row.action = string(last_action);
    history_row.action_reason = string(last_action_reason);
    history_row.cache_seed_hit = logical(local_getfield_or(cache_record, 'cache_hit', false));
    history_row.previous_design_count = local_getfield_or(diag, 'previous_design_count', 0);
    history_row.added_design_count = local_getfield_or(diag, 'added_design_count', 0);
    history_row.merged_design_count = local_getfield_or(diag, 'merged_design_count', height(local_getfield_or(run, 'design_table', table())));
    history_row.P_grid = reshape(local_getfield_or(current_domain, 'P_grid', []), 1, []);
    history_row.T_grid = reshape(local_getfield_or(current_domain, 'T_grid', []), 1, []);
    history_row.ns_search_min = local_getfield_or(current_domain, 'ns_search_min', NaN);
    history_row.ns_search_max = local_getfield_or(current_domain, 'ns_search_max', NaN);
    history_row.max_passratio = local_getfield_or(diag, 'max_passratio', NaN);
    history_row.frontier_points = local_getfield_or(diag, 'frontier_points', 0);
    history_row.internal_frontier_points = local_getfield_or(diag, 'internal_frontier_points', 0);
    history_row.internal_feasible_cells = local_getfield_or(diag, 'internal_feasible_cells', 0);
    history_row.upper_bound_hit_ratio = local_getfield_or(diag, 'upper_bound_hit_ratio', NaN);
    history_row.right_unity_reached = logical(local_getfield_or(diag, 'right_unity_reached', false));
    history_row.frontier_truncated = logical(local_getfield_or(diag, 'frontier_truncated', false));
    history_row.boundary_dominated = logical(local_getfield_or(diag, 'boundary_dominated', false));
    history_row.unity_plateau_reached = logical(local_getfield_or(diag, 'right_unity_reached', false));
    history_row.search_domain_label = string(format_mb_search_domain_label(current_domain, "short"));
    history_row.elapsed_s = toc(elapsed_start);

    [improved, best_metrics] = local_update_best_metrics(diag, best_metrics);
    if improved
        last_improvement_iteration = iteration;
    end

    decision = should_expand_mb_search_domain(current_domain, diag, history_rows, struct( ...
        'elapsed_s', history_row.elapsed_s, ...
        'max_iterations', max(1, local_getfield_or(current_domain, 'max_expand_iterations', 1) + 1), ...
        'time_budget_s', local_getfield_or(local_getfield_or(current_domain, 'expand_stop_policy', struct()), 'time_budget_s', inf), ...
        'last_improvement_iteration', last_improvement_iteration));

    history_row.stop_reason = string(local_getfield_or(decision, 'reason', ""));
    history_row.stop_reason_detail = string(local_getfield_or(decision, 'reason_detail', ""));
    history_rows(end + 1, 1) = history_row; %#ok<AGROW>
    cache_records(end + 1, 1) = cache_record; %#ok<AGROW>

    final_run = run;
    final_diag = diag;
    stop_reason = string(local_getfield_or(decision, 'reason', ""));
    stop_reason_detail = string(local_getfield_or(decision, 'reason_detail', ""));
    state = string(local_getfield_or(decision, 'state', "limit_reached"));

    if ~logical(local_getfield_or(decision, 'should_expand', false))
        break;
    end

    [next_domain, action] = propose_next_mb_search_domain(current_domain, diag, struct( ...
        'hard_max', local_getfield_or(current_domain, 'Ns_hard_max', NaN), ...
        'max_iterations', local_getfield_or(current_domain, 'max_expand_iterations', 1), ...
        'iteration', iteration));
    if local_domains_equivalent(current_domain, next_domain)
        stop_reason = "two_rounds_no_improvement";
        stop_reason_detail = "The proposed expansion did not change the effective search domain.";
        state = "stalled";
        history_rows(end).stop_reason = stop_reason;
        history_rows(end).stop_reason_detail = stop_reason_detail;
        break;
    end

    current_domain = next_domain;
    last_action = string(local_getfield_or(action, 'name', "expand_search_domain"));
    last_action_reason = string(local_getfield_or(action, 'reason', "Expand the search domain to resolve the right-side plateau or boundary-hit warnings."));
end

if isstruct(final_run) && ~isempty(fieldnames(final_run))
    final_run.incremental_search_history = build_mb_incremental_search_history(history_rows);
    final_run.expansion_state = struct( ...
        'state', state, ...
        'stop_reason', stop_reason, ...
        'stop_reason_detail', stop_reason_detail, ...
        'effective_search_domain', current_domain, ...
        'diagnostics', final_diag);
end

expansion = struct();
expansion.run = final_run;
expansion.effective_search_domain = current_domain;
expansion.history_rows = history_rows;
expansion.history_table = build_mb_incremental_search_history(history_rows);
expansion.cache_records = cache_records;
expansion.stop_reason = string(stop_reason);
expansion.stop_reason_detail = string(stop_reason_detail);
expansion.state = string(state);
expansion.final_diagnostics = final_diag;
end

function search_domain = local_normalize_search_domain(search_domain)
search_domain.P_grid = reshape(local_getfield_or(search_domain, 'P_grid', []), 1, []);
search_domain.T_grid = reshape(local_getfield_or(search_domain, 'T_grid', []), 1, []);
search_domain.Ns_expand_blocks = local_getfield_or(search_domain, 'Ns_expand_blocks', repmat(struct('name', "", 'ns_min', NaN, 'ns_step', NaN, 'ns_max', NaN, 'ns_values', []), 1, 0));
search_domain.max_expand_iterations = local_getfield_or(search_domain, 'max_expand_iterations', numel(search_domain.Ns_expand_blocks));
plan = build_mb_ns_search_plan(search_domain);
if ~isfield(search_domain, 'ns_search_min') || ~isfinite(search_domain.ns_search_min)
    search_domain.ns_search_min = local_first_finite(plan.initial.ns_min, local_ns_bound(search_domain.P_grid, search_domain.T_grid, 'min'));
end
if ~isfield(search_domain, 'ns_search_max') || ~isfinite(search_domain.ns_search_max)
    search_domain.ns_search_max = local_first_finite(plan.initial.ns_max, local_ns_bound(search_domain.P_grid, search_domain.T_grid, 'max'));
end
if ~isfield(search_domain, 'ns_search_step') || ~isfinite(search_domain.ns_search_step)
    search_domain.ns_search_step = local_first_finite(plan.initial.ns_step, local_min_grid_step(search_domain.T_grid));
end
search_domain.Ns_initial_range = [search_domain.ns_search_min, search_domain.ns_search_step, search_domain.ns_search_max];
search_domain.ns_search_plan = plan;
end

function diag = local_build_iteration_diagnostics(run, search_domain, options)
diag = struct();
aggregate = local_getfield_or(run, 'aggregate', struct());
h_km = local_getfield_or(options, 'height_km', local_getfield_or(run, 'h_km', NaN));
family_name = string(local_getfield_or(options, 'family_name', local_getfield_or(run, 'family_name', "")));
semantic_mode = string(local_getfield_or(options, 'semantic_mode', ""));

boundary_table = build_mb_boundary_hit_table(local_getfield_or(local_getfield_or(aggregate, 'requirement_surface_iP', struct()), 'surface_table', table()), search_domain, struct( ...
    'value_fields', {{'minimum_feasible_Ns'}}, ...
    'semantic_labels', {{char(semantic_mode)}}, ...
    'h_km', h_km, ...
    'family_name', family_name));
passratio_table = build_mb_passratio_saturation_diagnostics(local_getfield_or(aggregate, 'passratio_phasecurve', table()), search_domain, struct( ...
    'value_fields', {{'max_pass_ratio'}}, ...
    'semantic_labels', {{char(semantic_mode)}}, ...
    'h_km', h_km, ...
    'family_name', family_name));
frontier_table = build_mb_frontier_truncation_diagnostics(local_getfield_or(aggregate, 'frontier_vs_i', table()), search_domain, struct( ...
    'value_fields', {{'minimum_feasible_Ns'}}, ...
    'semantic_labels', {{char(semantic_mode)}}, ...
    'h_km', h_km, ...
    'family_name', family_name));

boundary_row = local_first_row(boundary_table);
passratio_row = local_first_row(passratio_table);
frontier_row = local_first_row(frontier_table);
latest_incremental = local_latest_incremental_row(local_getfield_or(run, 'incremental_search_history', table()));

diag.boundary_table = boundary_table;
diag.passratio_table = passratio_table;
diag.frontier_table = frontier_table;
diag.boundary_row = boundary_row;
diag.passratio_row = passratio_row;
diag.frontier_row = frontier_row;
diag.max_passratio = local_getfield_or(passratio_row, 'max_passratio', NaN);
diag.right_unity_reached = logical(local_getfield_or(passratio_row, 'right_unity_reached', false));
diag.first_unity_ns = local_getfield_or(passratio_row, 'first_unity_ns', NaN);
diag.internal_feasible_cells = local_getfield_or(boundary_row, 'num_internal_feasible_cells', 0);
diag.upper_bound_hit_ratio = local_getfield_or(boundary_row, 'ratio_upper_bound_hit', NaN);
diag.boundary_dominated = logical(local_getfield_or(boundary_row, 'is_boundary_dominated', false));
diag.frontier_points = local_getfield_or(frontier_row, 'num_frontier_points', 0);
diag.internal_frontier_points = local_getfield_or(frontier_row, 'num_internal_frontier_points', 0);
diag.frontier_defined_ratio = local_getfield_or(frontier_row, 'frontier_defined_ratio_over_inclinations', NaN);
diag.frontier_truncated = logical(local_getfield_or(frontier_row, 'frontier_truncated_by_upper_bound', false));
diag.frontier_weakly_defined = logical(local_getfield_or(frontier_row, 'frontier_weakly_defined', false));
diag.no_feasible_point_found = logical(local_getfield_or(boundary_row, 'num_no_feasible_cells', 0) >= local_getfield_or(boundary_row, 'num_total_cells', 1));
diag.search_domain_unsaturated = logical(local_getfield_or(passratio_row, 'is_search_domain_unsaturated', false)) || ...
    logical(local_getfield_or(boundary_row, 'search_upper_bound_likely_insufficient', false)) || ...
    logical(local_getfield_or(frontier_row, 'frontier_truncated_by_upper_bound', false));
diag.previous_design_count = local_table_or_field(latest_incremental, 'previous_design_count', 0);
diag.added_design_count = local_table_or_field(latest_incremental, 'added_design_count', height(local_getfield_or(run, 'design_table', table())));
diag.merged_design_count = local_table_or_field(latest_incremental, 'merged_design_count', height(local_getfield_or(run, 'design_table', table())));
end

function [improved, best_metrics] = local_update_best_metrics(diag, best_metrics)
improved = false;
if local_getfield_or(diag, 'max_passratio', -inf) > local_getfield_or(best_metrics, 'max_passratio', -inf) + 1.0e-9
    best_metrics.max_passratio = diag.max_passratio;
    improved = true;
end
if local_getfield_or(diag, 'frontier_points', -inf) > local_getfield_or(best_metrics, 'frontier_points', -inf)
    best_metrics.frontier_points = diag.frontier_points;
    improved = true;
end
if local_getfield_or(diag, 'internal_feasible_cells', -inf) > local_getfield_or(best_metrics, 'internal_cells', -inf)
    best_metrics.internal_cells = diag.internal_feasible_cells;
    improved = true;
end
end

function tf = local_domains_equivalent(a, b)
tf = isequal(reshape(local_getfield_or(a, 'P_grid', []), 1, []), reshape(local_getfield_or(b, 'P_grid', []), 1, [])) && ...
    isequal(reshape(local_getfield_or(a, 'T_grid', []), 1, []), reshape(local_getfield_or(b, 'T_grid', []), 1, [])) && ...
    isequal(local_getfield_or(a, 'ns_search_min', NaN), local_getfield_or(b, 'ns_search_min', NaN)) && ...
    isequal(local_getfield_or(a, 'ns_search_max', NaN), local_getfield_or(b, 'ns_search_max', NaN));
end

function row = local_empty_history_row()
row = struct( ...
    'iteration', 0, ...
    'semantic_mode', "", ...
    'sensor_group', "", ...
    'family_name', "", ...
    'height_km', NaN, ...
    'action', "", ...
    'action_reason', "", ...
    'stop_reason', "", ...
    'stop_reason_detail', "", ...
    'cache_seed_hit', false, ...
    'previous_design_count', 0, ...
    'added_design_count', 0, ...
    'merged_design_count', 0, ...
    'P_grid', [], ...
    'T_grid', [], ...
    'ns_search_min', NaN, ...
    'ns_search_max', NaN, ...
    'max_passratio', NaN, ...
    'frontier_points', 0, ...
    'internal_frontier_points', 0, ...
    'internal_feasible_cells', 0, ...
    'upper_bound_hit_ratio', NaN, ...
    'right_unity_reached', false, ...
    'frontier_truncated', false, ...
    'boundary_dominated', false, ...
    'unity_plateau_reached', false, ...
    'search_domain_label', "", ...
    'elapsed_s', NaN);
end

function row = local_first_row(T)
if istable(T) && ~isempty(T)
    row = table2struct(T(1, :), 'ToScalar', true);
else
    row = struct();
end
end

function row = local_latest_incremental_row(T)
if istable(T) && ~isempty(T)
    row = table2struct(T(end, :), 'ToScalar', true);
else
    row = struct();
end
end

function value = local_table_or_field(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function value = local_ns_bound(P_grid, T_grid, mode_name)
if isempty(P_grid) || isempty(T_grid)
    value = NaN;
    return;
end

function value = local_first_finite(primary_value, fallback_value)
if isfinite(primary_value)
    value = primary_value;
else
    value = fallback_value;
end
end
switch lower(mode_name)
    case 'min'
        value = min(P_grid) * min(T_grid);
    otherwise
        value = max(P_grid) * max(T_grid);
end
end

function step = local_min_grid_step(values)
values = unique(reshape(values, 1, []));
if numel(values) < 2
    step = NaN;
    return;
end
diffs = diff(values);
diffs = diffs(diffs > 0);
if isempty(diffs)
    step = NaN;
else
    step = min(diffs);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
