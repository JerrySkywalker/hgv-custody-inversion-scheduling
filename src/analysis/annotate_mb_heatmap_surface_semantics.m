function surface_out = annotate_mb_heatmap_surface_semantics(surface_in, search_domain, options)
%ANNOTATE_MB_HEATMAP_SURFACE_SEMANTICS Attach explicit numeric/state matrix semantics to a heatmap surface.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

surface_out = surface_in;
domain_mode = string(local_getfield_or(options, 'domain_mode', "local"));
x_values = local_resolve_axis_values(surface_in, search_domain, domain_mode, true);
y_values = local_resolve_axis_values(surface_in, search_domain, domain_mode, false);
surface_table = local_getfield_or(surface_in, 'surface_table', table());

surface_out.x_values = x_values(:);
surface_out.y_values = y_values(:);
surface_out.heatmap_surface_mode = domain_mode;
if domain_mode == "globalReplay"
    surface_out.matrix_domain_source = string(local_getfield_or(surface_in, 'matrix_domain_source', "global_i_p_skeleton"));
    if contains(surface_out.matrix_domain_source, "requirement_rebuild")
        surface_out.numeric_matrix_source_name = "global_rebuild_numeric_requirement_matrix";
        surface_out.state_matrix_source_name = "global_rebuild_discrete_state_matrix";
    else
        surface_out.numeric_matrix_source_name = "global_skeleton_numeric_requirement_matrix";
        surface_out.state_matrix_source_name = "global_skeleton_discrete_state_matrix";
    end
else
    surface_out.matrix_domain_source = "current_defined_surface";
    surface_out.numeric_matrix_source_name = "local_numeric_requirement_matrix";
    surface_out.state_matrix_source_name = "local_discrete_state_matrix";
end

surface_out.numeric_requirement_matrix = local_build_value_matrix(surface_table, x_values, y_values, 'minimum_feasible_Ns');
surface_out.margin_matrix = local_build_value_matrix(surface_table, x_values, y_values, 'best_joint_margin_at_min');
surface_out.value_matrix = surface_out.numeric_requirement_matrix;
surface_out.uses_numeric_requirement_matrix = true;
surface_out.uses_discrete_state_matrix = true;
surface_out.annotation_mode_numeric = "numeric_labels";
surface_out.annotation_mode_state = "state_only";
surface_out.global_skeleton_applied = domain_mode == "globalReplay";
surface_out.used_global_rebuild = logical(local_getfield_or(surface_in, 'used_global_rebuild', false));
surface_out.used_skeleton_projection = logical(local_getfield_or(surface_in, 'used_skeleton_projection', domain_mode == "globalReplay"));

[state_matrix, state_labels, state_table] = build_mb_heatmap_state_matrix(surface_out, search_domain, struct( ...
    'domain_mode', domain_mode, ...
    'x_values', x_values, ...
    'y_values', y_values));
surface_out.state_matrix = state_matrix;
surface_out.state_labels = state_labels;
surface_out.state_table = state_table;
end

function axis_values = local_resolve_axis_values(surface_in, search_domain, domain_mode, is_x_axis)
if is_x_axis
    local_field = 'x_values';
    global_field = 'global_P_grid';
    effective_field = 'effective_P_grid';
    default_field = 'P_grid';
    table_field = 'P';
else
    local_field = 'y_values';
    global_field = 'global_inclination_grid_deg';
    effective_field = 'effective_inclination_grid_deg';
    default_field = 'inclination_grid_deg';
    table_field = 'i_deg';
end

if string(domain_mode) == "globalReplay"
    axis_values = local_pick_axis( ...
        local_getfield_or(search_domain, global_field, []), ...
        local_getfield_or(surface_in, local_field, []), ...
        local_getfield_or(search_domain, default_field, []), ...
        local_get_table_column(surface_in, table_field));
else
    axis_values = local_pick_axis( ...
        local_getfield_or(surface_in, local_field, []), ...
        local_getfield_or(search_domain, effective_field, []), ...
        local_getfield_or(search_domain, default_field, []), ...
        local_get_table_column(surface_in, table_field));
end
end

function axis_values = local_pick_axis(varargin)
axis_values = [];
for idx = 1:nargin
    candidate = reshape(varargin{idx}, 1, []);
    candidate = candidate(isfinite(candidate));
    if isempty(candidate)
        continue;
    end
    axis_values = unique(candidate, 'sorted');
    return;
end
end

function values = local_get_table_column(surface_in, field_name)
surface_table = local_getfield_or(surface_in, 'surface_table', table());
if istable(surface_table) && ismember(field_name, surface_table.Properties.VariableNames)
    values = surface_table.(field_name);
else
    values = [];
end
end

function value_matrix = local_build_value_matrix(surface_table, x_values, y_values, field_name)
value_matrix = nan(numel(y_values), numel(x_values));
if isempty(surface_table) || ~ismember(field_name, surface_table.Properties.VariableNames)
    return;
end
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        hit = surface_table(abs(surface_table.P - x_values(ix)) < 1.0e-9 & abs(surface_table.i_deg - y_values(iy)) < 1.0e-9, :);
        if isempty(hit)
            continue;
        end
        value = hit.(field_name)(1);
        if isnumeric(value) && isfinite(value)
            value_matrix(iy, ix) = value;
        end
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
