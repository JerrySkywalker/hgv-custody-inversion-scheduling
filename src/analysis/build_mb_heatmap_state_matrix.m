function [state_matrix, state_labels, state_table] = build_mb_heatmap_state_matrix(surface, search_domain, options)
%BUILD_MB_HEATMAP_STATE_MATRIX Build a discrete heatmap-state matrix from the surface table.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

surface_table = local_getfield_or(surface, 'surface_table', table());
x_values = local_resolve_axis_values(surface, options, 'x_values', 'P');
y_values = local_resolve_axis_values(surface, options, 'y_values', 'i_deg');
state_labels = ["undefined / uncomputed", "evaluated infeasible", "boundary suspect", "defined internal", "refined/overcompute"];
state_matrix = zeros(numel(y_values), numel(x_values));
state_table = table();

if isempty(x_values) || isempty(y_values)
    return;
end

h_km = local_getfield_or(surface, 'h_km', local_pick_table_scalar(surface_table, 'h_km', NaN));
family_name = string(local_getfield_or(surface, 'family_name', local_pick_table_scalar(surface_table, 'family_name', "")));
domain_mode = string(local_getfield_or(options, 'domain_mode', local_getfield_or(surface, 'heatmap_surface_mode', "local")));
ns_upper = local_resolve_ns_upper_bound(search_domain, domain_mode);
ns_tol = max(4, 0.03 * max(1, abs(local_first_finite(ns_upper, 0))));

rows = cell(numel(y_values) * numel(x_values), 8);
cursor = 0;
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        cursor = cursor + 1;
        hit = local_lookup_surface_row(surface_table, x_values(ix), y_values(iy));
        is_boundary_suspect = false;
        is_refined = false;
        state_code = 0;
        if ~isempty(hit)
            num_total = local_pick_table_scalar(hit, 'num_total', 0);
            min_ns = local_pick_table_scalar(hit, 'minimum_feasible_Ns', NaN);
            if isfinite(min_ns)
                is_boundary_suspect = ix == numel(x_values) || iy == numel(y_values) || ...
                    (isfinite(ns_upper) && min_ns >= ns_upper - ns_tol);
                is_refined = local_row_has_refinement_or_overcompute(hit);
                if is_refined
                    state_code = 4;
                elseif is_boundary_suspect
                    state_code = 2;
                else
                    state_code = 3;
                end
            elseif num_total > 0
                state_code = 1;
            end
        end
        state_matrix(iy, ix) = state_code;
        rows(cursor, :) = { ...
            double(h_km), ...
            string(family_name), ...
            double(y_values(iy)), ...
            double(x_values(ix)), ...
            double(state_code), ...
            string(state_labels(state_code + 1)), ...
            logical(is_boundary_suspect), ...
            logical(is_refined)};
    end
end

state_table = cell2table(rows, 'VariableNames', { ...
    'h_km', 'family_name', 'i_deg', 'P', 'state_code', 'state_label', 'is_boundary_suspect', 'is_refined_or_overcomputed'});
end

function axis_values = local_resolve_axis_values(surface, options, option_field, table_field)
axis_values = reshape(local_getfield_or(options, option_field, []), 1, []);
axis_values = axis_values(isfinite(axis_values));
if ~isempty(axis_values)
    axis_values = unique(axis_values, 'sorted');
    return;
end
surface_values = reshape(local_getfield_or(surface, option_field, []), 1, []);
surface_values = surface_values(isfinite(surface_values));
if ~isempty(surface_values)
    axis_values = unique(surface_values, 'sorted');
    return;
end
surface_values = reshape(local_getfield_or(surface, strrep(option_field, '_values', ''), []), 1, []);
surface_values = surface_values(isfinite(surface_values));
if ~isempty(surface_values)
    axis_values = unique(surface_values, 'sorted');
    return;
end
surface_table = local_getfield_or(surface, 'surface_table', table());
if istable(surface_table) && ismember(table_field, surface_table.Properties.VariableNames)
    axis_values = unique(surface_table.(table_field), 'sorted');
else
    axis_values = [];
end
end

function ns_upper = local_resolve_ns_upper_bound(search_domain, domain_mode)
if string(domain_mode) == "globalReplay"
    ns_upper = local_first_finite( ...
        local_getfield_or(search_domain, 'history_ns_max', NaN), ...
        local_getfield_or(search_domain, 'ns_search_max', NaN), ...
        local_getfield_or(search_domain, 'effective_ns_max', NaN));
else
    ns_upper = local_first_finite( ...
        local_getfield_or(search_domain, 'effective_ns_max', NaN), ...
        local_getfield_or(search_domain, 'ns_search_max', NaN), ...
        local_getfield_or(search_domain, 'history_ns_max', NaN));
end
end

function hit = local_lookup_surface_row(surface_table, p_value, i_value)
if isempty(surface_table) || ~all(ismember({'P', 'i_deg'}, surface_table.Properties.VariableNames))
    hit = table();
    return;
end
hit = surface_table(abs(surface_table.P - p_value) < 1.0e-9 & abs(surface_table.i_deg - i_value) < 1.0e-9, :);
if height(hit) > 1
    hit = hit(1, :);
end
end

function tf = local_row_has_refinement_or_overcompute(row_table)
tf = false;
if isempty(row_table)
    return;
end
if ismember('aesthetic_overcompute_touched', row_table.Properties.VariableNames)
    tf = tf || logical(row_table.aesthetic_overcompute_touched(1));
end
if ismember('frontier_refinement_touched', row_table.Properties.VariableNames)
    tf = tf || logical(row_table.frontier_refinement_touched(1));
end
if ismember('aesthetic_overcompute_status', row_table.Properties.VariableNames)
    tf = tf || contains(string(row_table.aesthetic_overcompute_status(1)), "overcompute");
end
if ismember('frontier_refinement_status', row_table.Properties.VariableNames)
    tf = tf || contains(string(row_table.frontier_refinement_status(1)), "refinement");
end
end

function value = local_pick_table_scalar(T, field_name, fallback)
if istable(T) && ~isempty(T) && ismember(field_name, T.Properties.VariableNames)
    value = T.(field_name)(1);
else
    value = fallback;
end
end

function value = local_first_finite(varargin)
value = NaN;
for idx = 1:nargin
    candidate = varargin{idx};
    if isscalar(candidate) && isnumeric(candidate) && isfinite(candidate)
        value = candidate;
        return;
    end
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
