function summary_table = build_mb_heatmap_edge_truncation_diagnostics(surface_table, search_domain, options)
%BUILD_MB_HEATMAP_EDGE_TRUNCATION_DIAGNOSTICS Summarize whether a heatmap is only defined along its upper/right edge.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

h_km = local_resolve_context_value(surface_table, options, 'h_km', NaN);
family_name = string(local_resolve_context_value(surface_table, options, 'family_name', ""));
semantic_mode = string(local_getfield_or(options, 'semantic_mode', "unknown"));

summary_table = table('Size', [1, 19], ...
    'VariableTypes', {'double', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'logical', 'logical', 'logical', 'logical', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'h_km', 'family_name', 'semantic_mode', 'num_total_cells', 'num_feasible_cells', ...
    'num_right_edge_feasible_cells', 'num_top_edge_feasible_cells', 'num_edge_suspect_cells', ...
    'feasible_cell_ratio', 'frontier_like_cell_ratio', 'rightmost_two_column_ratio', 'right_edge_only_pattern', ...
    'top_edge_coverage_insufficient', 'frontier_coverage_low', 'comparison_gap_infinite_suspected', 'should_overcompute', ...
    'right_edge_feasible_ratio', 'frontier_defined_ratio_hint', 'diagnostic_note'});

if ~istable(surface_table) || isempty(surface_table) || ~all(ismember({'P', 'i_deg', 'minimum_feasible_Ns'}, surface_table.Properties.VariableNames))
    summary_table(1, :) = {h_km, family_name, semantic_mode, 0, 0, 0, 0, 0, 0, 0, 0, false, false, false, false, 0, 0, 0, "no heatmap cell available"};
    return;
end

values = surface_table.minimum_feasible_Ns;
finite_mask = isfinite(values);
num_total = height(surface_table);
num_feasible = sum(finite_mask);
max_P = max(surface_table.P, [], 'omitnan');
max_i = max(surface_table.i_deg, [], 'omitnan');
P_values = unique(surface_table.P, 'sorted');
two_col_threshold = max_P;
if numel(P_values) >= 2
    two_col_threshold = P_values(max(1, numel(P_values) - 1));
end
ns_max = local_getfield_or(search_domain, 'ns_search_max', NaN);
ns_step = local_getfield_or(search_domain, 'ns_search_step', 1);
tol = max(1.0e-9, 0.25 * max(1, ns_step));

right_edge_mask = finite_mask & surface_table.P >= max_P - 1.0e-9;
top_edge_mask = finite_mask & surface_table.i_deg >= max_i - 1.0e-9;
edge_suspect_mask = finite_mask & (right_edge_mask | top_edge_mask | (isfinite(ns_max) & values >= ns_max - tol));
rightmost_two_mask = finite_mask & surface_table.P >= two_col_threshold - 1.0e-9;

right_edge_ratio = local_safe_ratio(sum(right_edge_mask), max(num_feasible, 1));
rightmost_two_ratio = local_safe_ratio(sum(rightmost_two_mask), max(num_feasible, 1));
frontier_like_ratio = local_safe_ratio(sum(edge_suspect_mask), max(num_feasible, 1));
frontier_defined_ratio_hint = local_getfield_or(options, 'frontier_defined_ratio_hint', NaN);
comparison_gap_inf_hint = logical(local_getfield_or(options, 'comparison_gap_infinite_suspected', false));
frontier_coverage_low = isfinite(frontier_defined_ratio_hint) && frontier_defined_ratio_hint <= 0.35;
right_edge_only = num_feasible > 0 && (right_edge_ratio >= 0.80 || rightmost_two_ratio >= 0.90);
top_edge_insufficient = num_feasible > 0 && sum(top_edge_mask) <= max(1, ceil(0.15 * max(num_feasible, 1)));
feasible_cell_ratio = local_safe_ratio(num_feasible, num_total);
should_overcompute = logical(num_feasible > 0 && ( ...
    right_edge_only || ...
    frontier_like_ratio >= 0.70 || ...
    feasible_cell_ratio <= 0.20 || ...
    top_edge_insufficient || ...
    frontier_coverage_low || ...
    comparison_gap_inf_hint));

summary_table(1, :) = { ...
    h_km, ...
    family_name, ...
    semantic_mode, ...
    num_total, ...
    num_feasible, ...
    sum(right_edge_mask), ...
    sum(top_edge_mask), ...
    sum(edge_suspect_mask), ...
    feasible_cell_ratio, ...
    frontier_like_ratio, ...
    rightmost_two_ratio, ...
    logical(right_edge_only), ...
    logical(top_edge_insufficient), ...
    logical(frontier_coverage_low), ...
    logical(comparison_gap_inf_hint), ...
    logical(should_overcompute), ...
    right_edge_ratio, ...
    frontier_defined_ratio_hint, ...
    local_build_note(num_feasible, right_edge_only, top_edge_insufficient, frontier_coverage_low, comparison_gap_inf_hint, should_overcompute)};
end

function value = local_resolve_context_value(surface_table, options, field_name, fallback)
value = local_getfield_or(options, field_name, fallback);
if ~isequaln(value, fallback)
    return;
end
if istable(surface_table) && ismember(field_name, surface_table.Properties.VariableNames) && ~isempty(surface_table)
    column = surface_table.(field_name);
    value = column(1);
end
end

function ratio = local_safe_ratio(num_value, den_value)
if den_value <= 0
    ratio = 0;
else
    ratio = num_value / den_value;
end
end

function note = local_build_note(num_feasible, right_edge_only, top_edge_insufficient, frontier_coverage_low, comparison_gap_inf_hint, should_overcompute)
if num_feasible == 0
    note = "no feasible heatmap cell found";
elseif right_edge_only
    note = "feasible cells concentrate on the right boundary; local overcompute is recommended";
elseif top_edge_insufficient
    note = "upper-edge coverage is sparse; local overcompute is recommended";
elseif frontier_coverage_low
    note = "frontier coverage remains weak; local overcompute is recommended";
elseif comparison_gap_inf_hint
    note = "comparison gap suggests a truncated closed-side frontier; local overcompute is recommended";
elseif should_overcompute
    note = "feasible cells are sparse near the frontier; local overcompute is recommended";
else
    note = "heatmap coverage looks internally resolved for the current grid";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
