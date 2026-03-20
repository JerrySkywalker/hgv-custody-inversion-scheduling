function summary_table = build_mb_boundary_hit_table(surface_table, search_domain, options)
%BUILD_MB_BOUNDARY_HIT_TABLE Summarize minimum-Ns heatmap boundary hits for one or more semantics.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

[value_fields, semantic_labels] = local_resolve_value_fields(surface_table, options);
h_km = local_resolve_context_value(surface_table, options, 'h_km', NaN);
family_name = string(local_resolve_context_value(surface_table, options, 'family_name', ""));
ns_min = local_resolve_search_bound(search_domain, surface_table, value_fields, 'min');
ns_max = local_resolve_search_bound(search_domain, surface_table, value_fields, 'max');
tol = max(1.0e-9, 0.25 * max(1, local_getfield_or(search_domain, 'ns_search_step', 1)));

summary_table = table('Size', [numel(value_fields), 17], ...
    'VariableTypes', {'double', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'logical', 'logical', 'string', 'double'}, ...
    'VariableNames', {'h_km', 'family_name', 'semantic_mode', 'search_ns_min', 'search_ns_max', ...
    'num_total_cells', 'num_internal_feasible_cells', 'num_upper_bound_hit_cells', 'num_lower_bound_hit_cells', ...
    'num_no_feasible_cells', 'ratio_internal_feasible', 'ratio_upper_bound_hit', 'ratio_lower_bound_hit', ...
    'is_boundary_dominated', 'search_upper_bound_likely_insufficient', 'diagnostic_note', 'ratio_no_feasible'});

for idx = 1:numel(value_fields)
    field_name = value_fields{idx};
    values = local_get_numeric_column(surface_table, field_name);
    total_cells = numel(values);

    finite_mask = isfinite(values);
    upper_hit = finite_mask & isfinite(ns_max) & values >= ns_max - tol;
    lower_hit = finite_mask & isfinite(ns_min) & values <= ns_min + tol;
    internal_feasible = finite_mask & ~upper_hit & ~lower_hit;
    no_feasible = ~finite_mask;

    ratio_internal = local_safe_ratio(sum(internal_feasible), total_cells);
    ratio_upper = local_safe_ratio(sum(upper_hit), total_cells);
    ratio_lower = local_safe_ratio(sum(lower_hit), total_cells);
    ratio_no_feasible = local_safe_ratio(sum(no_feasible), total_cells);
    boundary_dominated = ratio_upper >= 0.50;
    upper_bound_note = boundary_dominated || (sum(upper_hit) >= max(1, ceil(0.35 * max(sum(finite_mask), 1))));

    summary_table(idx, :) = { ...
        h_km, ...
        family_name, ...
        string(semantic_labels{idx}), ...
        ns_min, ...
        ns_max, ...
        total_cells, ...
        sum(internal_feasible), ...
        sum(upper_hit), ...
        sum(lower_hit), ...
        sum(no_feasible), ...
        ratio_internal, ...
        ratio_upper, ...
        ratio_lower, ...
        logical(boundary_dominated), ...
        logical(upper_bound_note), ...
        local_boundary_note(sum(finite_mask), sum(upper_hit), sum(lower_hit), sum(no_feasible), total_cells), ...
        ratio_no_feasible};
end
end

function [value_fields, semantic_labels] = local_resolve_value_fields(surface_table, options)
value_fields = local_getfield_or(options, 'value_fields', {});
semantic_labels = cellstr(string(local_getfield_or(options, 'semantic_labels', {})));
if isempty(value_fields)
    if istable(surface_table) && ismember('minimum_feasible_Ns', surface_table.Properties.VariableNames)
        value_fields = {'minimum_feasible_Ns'};
        semantic_labels = {'unknown'};
    elseif istable(surface_table)
        candidate_fields = surface_table.Properties.VariableNames(contains(surface_table.Properties.VariableNames, 'minimum_feasible_Ns'));
        value_fields = cellstr(candidate_fields(:));
        semantic_labels = regexprep(value_fields, '^minimum_feasible_Ns_?', '');
    else
        value_fields = {'minimum_feasible_Ns'};
        semantic_labels = {'unknown'};
    end
end
if isempty(semantic_labels) || numel(semantic_labels) ~= numel(value_fields)
    semantic_labels = value_fields;
end
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

function bound = local_resolve_search_bound(search_domain, surface_table, value_fields, mode_name)
if strcmpi(mode_name, 'min')
    bound = local_getfield_or(search_domain, 'ns_search_min', NaN);
else
    bound = local_getfield_or(search_domain, 'ns_search_max', NaN);
end
if isfinite(bound)
    return;
end

    values = [];
    for idx = 1:numel(value_fields)
        values = [values; local_get_numeric_column(surface_table, value_fields{idx})]; %#ok<AGROW>
    end
    values = values(isfinite(values));
    if isempty(values)
        bound = NaN;
    elseif strcmpi(mode_name, 'min')
        bound = min(values);
    else
        bound = max(values);
    end
end

function values = local_get_numeric_column(surface_table, field_name)
if istable(surface_table) && ismember(field_name, surface_table.Properties.VariableNames)
    values = surface_table.(field_name);
else
    values = NaN(0, 1);
end
values = reshape(values, [], 1);
end

function ratio = local_safe_ratio(num_value, den_value)
if den_value <= 0
    ratio = 0;
else
    ratio = num_value / den_value;
end
end

function note = local_boundary_note(num_feasible, num_upper, num_lower, num_no_feasible, num_total)
if num_total == 0
    note = "no heatmap cell available";
elseif num_feasible == 0
    note = "no feasible point found within current search domain";
elseif num_upper > 0 && num_upper >= max(1, ceil(0.5 * num_feasible))
    note = "boundary-dominated result; search upper bound likely insufficient";
elseif num_lower > 0
    note = "some cells sit on the lower search boundary";
elseif num_no_feasible > 0
    note = "feasible and infeasible regions coexist within the current search domain";
else
    note = "minimum-Ns heatmap is internally resolved within the current search domain";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
