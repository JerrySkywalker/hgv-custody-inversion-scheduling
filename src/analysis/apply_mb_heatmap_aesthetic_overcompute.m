function result = apply_mb_heatmap_aesthetic_overcompute(run, search_domain, evaluate_new_fn, aggregate_fn, options)
%APPLY_MB_HEATMAP_AESTHETIC_OVERCOMPUTE Add small local evaluations near a sparse/right-edge heatmap frontier.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || ~isa(evaluate_new_fn, 'function_handle')
    error('apply_mb_heatmap_aesthetic_overcompute requires evaluate_new_fn.');
end
if nargin < 4 || ~isa(aggregate_fn, 'function_handle')
    error('apply_mb_heatmap_aesthetic_overcompute requires aggregate_fn.');
end
if nargin < 5 || isempty(options)
    options = struct();
end

mode_name = lower(strtrim(char(string(local_getfield_or(options, 'mode', "off")))));
summary_table = local_empty_summary_table();
result = struct('run', run, 'summary_table', summary_table, 'applied', false, 'candidate_design_table', table());
if strcmp(mode_name, 'off')
    summary_table(1, :) = local_build_summary_row(run, mode_name, false, false, 0, 0, 0, 0, 0, false, "overcompute disabled");
    result.summary_table = summary_table;
    return;
end

surface = local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'requirement_surface_iP', struct());
surface_table = local_getfield_or(surface, 'surface_table', table());
diag = build_mb_heatmap_edge_truncation_diagnostics(surface_table, search_domain, struct( ...
    'semantic_mode', local_getfield_or(options, 'semantic_mode', "unknown"), ...
    'h_km', local_getfield_or(run, 'h_km', NaN), ...
    'family_name', string(local_getfield_or(run, 'family_name', ""))));
diag_row = table2struct(diag(1, :), 'ToScalar', true);
if ~logical(local_getfield_or(diag_row, 'should_overcompute', false))
    summary_table(1, :) = local_build_summary_row(run, mode_name, true, false, local_getfield_or(diag_row, 'num_edge_suspect_cells', 0), 0, 0, 0, 0, false, string(local_getfield_or(diag_row, 'diagnostic_note', "")));
    result.summary_table = summary_table;
    return;
end

[candidate_cells, candidate_designs, budget_hit] = local_propose_candidate_designs(run, search_domain, options);
if isempty(candidate_cells) || isempty(candidate_designs)
    summary_table(1, :) = local_build_summary_row(run, mode_name, true, false, local_getfield_or(diag_row, 'num_edge_suspect_cells', 0), 0, 0, 0, 0, budget_hit, "no additional candidate cell survived deduplication");
    result.summary_table = summary_table;
    return;
end

new_eval = evaluate_new_fn(candidate_designs);
merged_design_table = local_merge_tables(local_getfield_or(run, 'design_table', table()), candidate_designs, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'});
merged_eval_table = local_merge_tables(local_getfield_or(run, 'eval_table', table()), local_getfield_or(new_eval, 'eval_table', table()), {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'});
merged_feasible_table = local_pick_feasible_rows(merged_eval_table);
merged_aggregate = aggregate_fn(merged_eval_table);

base_surface = local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'requirement_surface_iP', struct());
base_frontier = local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'frontier_vs_i', table());
merged_surface = local_getfield_or(merged_aggregate, 'requirement_surface_iP', struct());
merged_frontier = local_getfield_or(merged_aggregate, 'frontier_vs_i', table());
merged_surface = local_annotate_surface_provenance(base_surface, merged_surface, candidate_cells);

run.design_table = merged_design_table;
run.eval_table = merged_eval_table;
run.feasible_table = merged_feasible_table;
run.aggregate.requirement_surface_iP_base = base_surface;
run.aggregate.frontier_vs_i_base = base_frontier;
run.aggregate.requirement_surface_iP = merged_surface;
run.aggregate.frontier_vs_i = merged_frontier;
run.aggregate.heatmap_overcompute_summary = table();
run.aggregate.heatmap_overcompute_summary = local_build_summary_row(run, mode_name, true, true, local_getfield_or(diag_row, 'num_edge_suspect_cells', 0), height(candidate_cells), height(candidate_designs), local_count_newly_defined(base_surface, merged_surface), local_count_improved(base_surface, merged_surface), budget_hit, "heatmap/frontier locally refined near sparse right-edge cells");
run.aggregate.heatmap_overcompute_summary.num_new_feasible_designs = height(local_getfield_or(new_eval, 'feasible_table', table()));
run.aggregate.heatmap_overcompute_candidate_cells = candidate_cells;
run.aggregate.heatmap_overcompute_diagnostics = diag;

result.run = run;
result.summary_table = run.aggregate.heatmap_overcompute_summary;
result.applied = true;
result.candidate_design_table = candidate_designs;
end

function [candidate_cells, candidate_designs, budget_hit] = local_propose_candidate_designs(run, search_domain, options)
surface_table = local_getfield_or(local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'requirement_surface_iP', struct()), 'surface_table', table());
design_table = local_getfield_or(run, 'design_table', table());
candidate_cells = table();
candidate_designs = table();
budget_hit = false;
if isempty(surface_table) || isempty(design_table)
    return;
end

mode_name = lower(strtrim(char(string(local_getfield_or(options, 'mode', "light")))));
defaults = struct('max_extra_cells', 6, 'max_extra_P_candidates', 1, 'max_extra_i_neighbors', 1, 'max_extra_designs', 96);
if strcmp(mode_name, 'moderate')
    defaults.max_extra_cells = 12;
    defaults.max_extra_P_candidates = 2;
    defaults.max_extra_i_neighbors = 2;
    defaults.max_extra_designs = 192;
end
cfg_budget = local_getfield_or(options, 'budget', struct());
budget = local_merge_structs(defaults, cfg_budget);

ns_max = local_getfield_or(search_domain, 'ns_search_max', NaN);
ns_hard_max = local_getfield_or(search_domain, 'Ns_hard_max', ns_max);
P_values = unique(reshape(local_getfield_or(search_domain, 'P_grid', design_table.P), 1, []), 'sorted');
T_values = unique(reshape(local_getfield_or(search_domain, 'T_grid', design_table.T), 1, []), 'sorted');
i_values = unique(reshape(local_getfield_or(search_domain, 'inclination_grid_deg', design_table.i_deg), 1, []), 'sorted');
P_step = local_positive_step(P_values, 2);
i_step = max(5, local_positive_step(i_values, 5) / 2);

finite_rows = surface_table(isfinite(surface_table.minimum_feasible_Ns), :);
if isempty(finite_rows)
    return;
end
right_edge = finite_rows.P >= max(P_values) - 1.0e-9;
near_ns_max = isfinite(ns_max) & finite_rows.minimum_feasible_Ns >= ns_max - max(1, 0.25 * local_getfield_or(search_domain, 'ns_search_step', 1));
suspect_rows = finite_rows(right_edge | near_ns_max, :);
if isempty(suspect_rows)
    suspect_rows = sortrows(finite_rows, 'minimum_feasible_Ns', 'descend');
end
suspect_rows = sortrows(suspect_rows, {'minimum_feasible_Ns', 'P', 'i_deg'}, {'descend', 'descend', 'ascend'});

cell_rows = {};
cell_cursor = 0;
for idx = 1:height(suspect_rows)
    base_P = suspect_rows.P(idx);
    base_i = suspect_rows.i_deg(idx);
    P_candidates = base_P + P_step * (1:budget.max_extra_P_candidates);
    i_candidates = base_i + (-budget.max_extra_i_neighbors:budget.max_extra_i_neighbors) * i_step;
    i_candidates = i_candidates(i_candidates >= min(i_values) & i_candidates <= max(i_values));
    i_candidates = unique([base_i, i_candidates], 'sorted');
    for idx_i = 1:numel(i_candidates)
        for idx_p = 1:numel(P_candidates)
            cell_cursor = cell_cursor + 1;
            cell_rows{cell_cursor, 1} = {local_getfield_or(run, 'h_km', NaN), i_candidates(idx_i), P_candidates(idx_p), "aesthetic_overcompute"}; %#ok<AGROW>
            if cell_cursor >= budget.max_extra_cells
                budget_hit = true;
                break;
            end
        end
        if cell_cursor >= budget.max_extra_cells
            break;
        end
    end
    if cell_cursor >= budget.max_extra_cells
        break;
    end
end

if cell_cursor == 0
    return;
end
candidate_cells = cell2table(vertcat(cell_rows{1:cell_cursor}), 'VariableNames', {'h_km', 'i_deg', 'P', 'cell_source'});
candidate_cells = unique(candidate_cells, 'rows', 'stable');

design_rows = {};
design_cursor = 0;
F_fixed = local_pick_F(design_table);
for idx = 1:height(candidate_cells)
    for idx_t = 1:numel(T_values)
        Ns = candidate_cells.P(idx) * T_values(idx_t);
        if isfinite(ns_hard_max) && Ns > ns_hard_max + 1.0e-9
            continue;
        end
        design_cursor = design_cursor + 1;
        design_rows{design_cursor, 1} = {candidate_cells.h_km(idx), candidate_cells.i_deg(idx), candidate_cells.P(idx), T_values(idx_t), F_fixed, Ns, "heatmap_overcompute"}; %#ok<AGROW>
        if design_cursor >= budget.max_extra_designs
            budget_hit = true;
            break;
        end
    end
    if design_cursor >= budget.max_extra_designs
        break;
    end
end

if design_cursor == 0
    candidate_designs = table();
    return;
end
candidate_designs = cell2table(vertcat(design_rows{1:design_cursor}), ...
    'VariableNames', {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'slice_source'});
candidate_designs = unique(candidate_designs, 'rows', 'stable');

if ~isempty(design_table)
    existing_keys = design_table(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'});
    [tf_existing, ~] = ismember(candidate_designs(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'}), existing_keys, 'rows');
    candidate_designs = candidate_designs(~tf_existing, :);
    if isempty(candidate_designs)
        candidate_cells = table();
    else
        candidate_cells = unique(candidate_designs(:, {'h_km', 'i_deg', 'P'}), 'rows', 'stable');
        candidate_cells.cell_source = repmat("aesthetic_overcompute", height(candidate_cells), 1);
    end
end
end

function annotated_surface = local_annotate_surface_provenance(base_surface, merged_surface, candidate_cells)
annotated_surface = merged_surface;
surface_table = local_getfield_or(merged_surface, 'surface_table', table());
if isempty(surface_table) || isempty(candidate_cells)
    return;
end

base_table = local_getfield_or(base_surface, 'surface_table', table());
surface_table.aesthetic_overcompute_touched = false(height(surface_table), 1);
surface_table.aesthetic_overcompute_status = repmat("base_search", height(surface_table), 1);

[tf_touch, ~] = ismember(surface_table(:, {'h_km', 'i_deg', 'P'}), candidate_cells(:, {'h_km', 'i_deg', 'P'}), 'rows');
surface_table.aesthetic_overcompute_touched = tf_touch;

if isempty(base_table)
    surface_table.aesthetic_overcompute_status(tf_touch) = "aesthetic_overcompute_checked";
    annotated_surface.surface_table = surface_table;
    return;
end

joined = outerjoin(surface_table(:, {'h_km', 'i_deg', 'P', 'minimum_feasible_Ns', 'aesthetic_overcompute_touched'}), ...
    base_table(:, {'h_km', 'i_deg', 'P', 'minimum_feasible_Ns'}), ...
    'Keys', {'h_km', 'i_deg', 'P'}, 'MergeKeys', true, 'Type', 'left', ...
    'LeftVariables', {'minimum_feasible_Ns', 'aesthetic_overcompute_touched'}, ...
    'RightVariables', {'minimum_feasible_Ns'});
joined = local_standardize_joined_surface_columns(joined, 'minimum_feasible_Ns_new', 'minimum_feasible_Ns_base');

for idx = 1:height(surface_table)
    if ~surface_table.aesthetic_overcompute_touched(idx)
        continue;
    end
    hit = joined.h_km == surface_table.h_km(idx) & joined.i_deg == surface_table.i_deg(idx) & joined.P == surface_table.P(idx);
    if ~any(hit)
        surface_table.aesthetic_overcompute_status(idx) = "aesthetic_overcompute_checked";
        continue;
    end
    old_value = joined.minimum_feasible_Ns_base(find(hit, 1));
    new_value = joined.minimum_feasible_Ns_new(find(hit, 1));
    if ~isfinite(old_value) && isfinite(new_value)
        surface_table.aesthetic_overcompute_status(idx) = "aesthetic_overcompute_newly_defined";
    elseif isfinite(old_value) && isfinite(new_value) && new_value < old_value - 1.0e-9
        surface_table.aesthetic_overcompute_status(idx) = "aesthetic_overcompute_improved";
    else
        surface_table.aesthetic_overcompute_status(idx) = "aesthetic_overcompute_checked";
    end
end
annotated_surface.surface_table = surface_table;
end

function count = local_count_newly_defined(base_surface, merged_surface)
count = 0;
base_table = local_getfield_or(base_surface, 'surface_table', table());
merged_table = local_getfield_or(merged_surface, 'surface_table', table());
if isempty(merged_table)
    return;
end
joined = outerjoin(merged_table(:, {'h_km', 'i_deg', 'P', 'minimum_feasible_Ns'}), base_table(:, {'h_km', 'i_deg', 'P', 'minimum_feasible_Ns'}), ...
    'Keys', {'h_km', 'i_deg', 'P'}, 'MergeKeys', true, 'Type', 'left', ...
    'LeftVariables', {'minimum_feasible_Ns'}, 'RightVariables', {'minimum_feasible_Ns'});
joined = local_standardize_joined_surface_columns(joined, 'new_value', 'old_value');
count = sum(~isfinite(joined.old_value) & isfinite(joined.new_value));
end

function count = local_count_improved(base_surface, merged_surface)
count = 0;
base_table = local_getfield_or(base_surface, 'surface_table', table());
merged_table = local_getfield_or(merged_surface, 'surface_table', table());
if isempty(base_table) || isempty(merged_table)
    return;
end
joined = innerjoin(merged_table(:, {'h_km', 'i_deg', 'P', 'minimum_feasible_Ns'}), base_table(:, {'h_km', 'i_deg', 'P', 'minimum_feasible_Ns'}), ...
    'Keys', {'h_km', 'i_deg', 'P'}, 'LeftVariables', {'minimum_feasible_Ns'}, 'RightVariables', {'minimum_feasible_Ns'});
joined = local_standardize_joined_surface_columns(joined, 'new_value', 'old_value');
count = sum(isfinite(joined.new_value) & isfinite(joined.old_value) & joined.new_value < joined.old_value - 1.0e-9);
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
elseif iscellstr(ref) || iscell(ref)
    values = repmat({''}, n, 1);
elseif islogical(ref)
    values = false(n, 1);
elseif isnumeric(ref)
    values = nan(n, 1);
else
    values = strings(n, 1);
end
end

function F_fixed = local_pick_F(design_table)
if isempty(design_table) || ~ismember('F', design_table.Properties.VariableNames) || isempty(design_table.F)
    F_fixed = 0;
else
    F_fixed = design_table.F(1);
end
end

function step = local_positive_step(values, fallback)
values = unique(reshape(values, 1, []), 'sorted');
diffs = diff(values);
diffs = diffs(diffs > 0);
if isempty(diffs)
    step = fallback;
else
    step = min(diffs);
end
end

function row = local_build_summary_row(run, mode_name, triggered, applied, suspect_cells, candidate_cells, extra_designs, newly_defined, improved_cells, budget_hit, note_text)
row = table( ...
    local_getfield_or(run, 'h_km', NaN), ...
    string(local_getfield_or(run, 'family_name', "")), ...
    string(local_getfield_or(local_getfield_or(run, 'summary', struct()), 'sensor_group', "")), ...
    string(local_getfield_or(local_getfield_or(run, 'eval_table', table()), 'semantic_mode', "unknown")), ...
    string(mode_name), ...
    logical(triggered), ...
    logical(applied), ...
    suspect_cells, ...
    candidate_cells, ...
    extra_designs, ...
    newly_defined, ...
    improved_cells, ...
    logical(budget_hit), ...
    string(note_text), ...
    'VariableNames', {'h_km', 'family_name', 'sensor_group', 'semantic_mode', 'overcompute_mode', ...
    'triggered', 'applied', 'num_suspect_cells', 'num_candidate_cells', 'num_extra_designs', ...
    'num_cells_newly_defined', 'num_cells_improved', 'budget_hit', 'note'});
end

function T = local_empty_summary_table()
T = table('Size', [0, 14], ...
    'VariableTypes', {'double', 'string', 'string', 'string', 'string', 'logical', 'logical', 'double', 'double', 'double', 'double', 'double', 'logical', 'string'}, ...
    'VariableNames', {'h_km', 'family_name', 'sensor_group', 'semantic_mode', 'overcompute_mode', ...
    'triggered', 'applied', 'num_suspect_cells', 'num_candidate_cells', 'num_extra_designs', ...
    'num_cells_newly_defined', 'num_cells_improved', 'budget_hit', 'note'});
end

function merged = local_merge_structs(base, override)
merged = base;
fields = fieldnames(override);
for idx = 1:numel(fields)
    merged.(fields{idx}) = override.(fields{idx});
end
end

function joined = local_standardize_joined_surface_columns(joined, left_name, right_name)
vars = joined.Properties.VariableNames;
min_vars = vars(contains(vars, 'minimum_feasible_Ns'));
if numel(min_vars) >= 1
    joined.Properties.VariableNames{strcmp(vars, min_vars{1})} = left_name;
end
vars = joined.Properties.VariableNames;
remaining = vars(contains(vars, 'minimum_feasible_Ns'));
if numel(remaining) >= 1
    joined.Properties.VariableNames{strcmp(vars, remaining{1})} = right_name;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
elseif istable(S) && ismember(field_name, S.Properties.VariableNames) && ~isempty(S)
    value = S.(field_name)(1);
else
    value = fallback;
end
end
