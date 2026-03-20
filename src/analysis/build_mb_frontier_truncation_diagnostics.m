function summary_table = build_mb_frontier_truncation_diagnostics(frontier_table, search_domain, options)
%BUILD_MB_FRONTIER_TRUNCATION_DIAGNOSTICS Summarize frontier truncation and definition strength.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

[value_fields, semantic_labels] = local_resolve_value_fields(frontier_table, options);
h_km = local_resolve_context_value(frontier_table, options, 'h_km', NaN);
family_name = string(local_resolve_context_value(frontier_table, options, 'family_name', ""));
ns_min = local_resolve_search_bound(search_domain, frontier_table, value_fields, 'min');
ns_max = local_resolve_search_bound(search_domain, frontier_table, value_fields, 'max');
tol = max(1.0e-9, 0.25 * max(1, local_getfield_or(search_domain, 'ns_search_step', 1)));
num_total_inclinations = max(height(frontier_table), 1);

summary_table = table('Size', [numel(value_fields), 12], ...
    'VariableTypes', {'double', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'logical', 'logical', 'string'}, ...
    'VariableNames', {'h_km', 'family_name', 'semantic_mode', 'search_ns_min', 'search_ns_max', ...
    'num_frontier_points', 'num_boundary_frontier_points', 'num_internal_frontier_points', ...
    'frontier_defined_ratio_over_inclinations', 'frontier_truncated_by_upper_bound', ...
    'frontier_weakly_defined', 'diagnostic_note'});

for idx = 1:numel(value_fields)
    field_name = value_fields{idx};
    values = local_get_numeric_column(frontier_table, field_name);
    defined_mask = isfinite(values);
    boundary_mask = defined_mask & isfinite(ns_max) & values >= ns_max - tol;
    lower_mask = defined_mask & isfinite(ns_min) & values <= ns_min + tol;
    internal_mask = defined_mask & ~boundary_mask & ~lower_mask;
    weakly_defined = sum(defined_mask) <= 1;

    summary_table(idx, :) = { ...
        h_km, ...
        family_name, ...
        string(semantic_labels{idx}), ...
        ns_min, ...
        ns_max, ...
        sum(defined_mask), ...
        sum(boundary_mask), ...
        sum(internal_mask), ...
        sum(defined_mask) / num_total_inclinations, ...
        logical(any(boundary_mask)), ...
        logical(weakly_defined), ...
        local_frontier_note(sum(defined_mask), sum(boundary_mask), weakly_defined)};
end
end

function [value_fields, semantic_labels] = local_resolve_value_fields(frontier_table, options)
value_fields = local_getfield_or(options, 'value_fields', {});
semantic_labels = cellstr(string(local_getfield_or(options, 'semantic_labels', {})));
if isempty(value_fields)
    if istable(frontier_table) && ismember('minimum_feasible_Ns', frontier_table.Properties.VariableNames)
        value_fields = {'minimum_feasible_Ns'};
        semantic_labels = {'unknown'};
    else
        candidate_fields = frontier_table.Properties.VariableNames(contains(frontier_table.Properties.VariableNames, 'minimum_feasible_Ns'));
        value_fields = cellstr(candidate_fields(:));
        semantic_labels = regexprep(value_fields, '^minimum_feasible_Ns_?', '');
    end
end
if isempty(semantic_labels) || numel(semantic_labels) ~= numel(value_fields)
    semantic_labels = value_fields;
end
end

function value = local_resolve_context_value(frontier_table, options, field_name, fallback)
value = local_getfield_or(options, field_name, fallback);
if ~isequaln(value, fallback)
    return;
end
if istable(frontier_table) && ismember(field_name, frontier_table.Properties.VariableNames) && ~isempty(frontier_table)
    column = frontier_table.(field_name);
    value = column(1);
end
end

function bound = local_resolve_search_bound(search_domain, frontier_table, value_fields, mode_name)
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
    values = [values; local_get_numeric_column(frontier_table, value_fields{idx})]; %#ok<AGROW>
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

function values = local_get_numeric_column(frontier_table, field_name)
if istable(frontier_table) && ismember(field_name, frontier_table.Properties.VariableNames)
    values = frontier_table.(field_name);
else
    values = NaN(0, 1);
end
values = reshape(values, [], 1);
end

function note = local_frontier_note(num_defined, num_boundary, weakly_defined)
if num_defined == 0
    note = "no feasible point found within current search domain";
elseif weakly_defined
    note = "frontier weakly defined under current domain";
elseif num_boundary > 0
    note = "frontier is truncated by the current search upper bound";
else
    note = "frontier is internally defined within the current search domain";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
