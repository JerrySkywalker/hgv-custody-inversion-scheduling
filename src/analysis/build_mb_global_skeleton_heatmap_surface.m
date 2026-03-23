function surface_out = build_mb_global_skeleton_heatmap_surface(surface_in, search_domain, options)
%BUILD_MB_GLOBAL_SKELETON_HEATMAP_SURFACE Reproject a local requirement surface onto the full configured P-i grid.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

surface_out = surface_in;
surface_table = local_getfield_or(surface_in, 'surface_table', table());
x_values = local_resolve_axis_values(search_domain, surface_in, 'global_P_grid', 'P_grid', 'x_values', 'P');
y_values = local_resolve_axis_values(search_domain, surface_in, 'global_inclination_grid_deg', 'inclination_grid_deg', 'y_values', 'i_deg');
if isempty(x_values) || isempty(y_values)
    return;
end

runtime_cfg = local_getfield_or(options, 'runtime', struct());
plot_mode_profile = local_getfield_or(options, 'plot_mode_profile', struct());
policy = local_getfield_or(options, 'plot_data_policy', resolve_mb_plot_data_policy(runtime_cfg, struct( ...
    'plot_mode_profile', plot_mode_profile, ...
    'heatmap_value_mode', "numeric_requirement", ...
    'heatmap_domain_mode', "globalSkeleton")));

if logical(local_getfield_or(policy, 'used_global_rebuild_required', false))
    [surface_out, rebuild_meta] = rebuild_mb_requirement_surface_for_heatmap(surface_in, search_domain, struct( ...
        'raw_eval_table', local_getfield_or(options, 'raw_eval_table', table()), ...
        'x_values', x_values, ...
        'y_values', y_values, ...
        'h_km', local_getfield_or(options, 'h_km', NaN), ...
        'family_name', local_getfield_or(options, 'family_name', "")));
    surface_out.used_global_rebuild = logical(local_getfield_or(rebuild_meta, 'used_global_rebuild', false));
    surface_out.used_skeleton_projection = logical(local_getfield_or(rebuild_meta, 'used_skeleton_projection', false));
else
    full_table = local_build_full_grid_table(surface_table, x_values, y_values, options);
    surface_out.surface_table = full_table;
    surface_out.x_values = x_values(:);
    surface_out.y_values = y_values(:);
    surface_out.value_matrix = local_build_value_matrix(full_table, x_values, y_values, 'minimum_feasible_Ns');
    surface_out.numeric_requirement_matrix = surface_out.value_matrix;
    surface_out.margin_matrix = local_build_value_matrix(full_table, x_values, y_values, 'best_joint_margin_at_min');
    surface_out.surface_name = string(local_getfield_or(surface_in, 'surface_name', "requirement_surface")) + "_globalSkeleton";
    surface_out.heatmap_surface_mode = "globalSkeleton";
    surface_out.matrix_domain_source = "global_i_p_skeleton";
    surface_out.global_skeleton_applied = true;
    surface_out.used_global_rebuild = false;
    surface_out.used_skeleton_projection = true;
end
end

function axis_values = local_resolve_axis_values(search_domain, surface_in, primary_search_field, secondary_search_field, surface_field, table_field)
axis_values = reshape(local_getfield_or(search_domain, primary_search_field, []), 1, []);
axis_values = axis_values(isfinite(axis_values));
if ~isempty(axis_values)
    axis_values = unique(axis_values, 'sorted');
    return;
end
axis_values = reshape(local_getfield_or(search_domain, secondary_search_field, []), 1, []);
axis_values = axis_values(isfinite(axis_values));
if ~isempty(axis_values)
    axis_values = unique(axis_values, 'sorted');
    return;
end
axis_values = reshape(local_getfield_or(surface_in, surface_field, []), 1, []);
axis_values = axis_values(isfinite(axis_values));
if ~isempty(axis_values)
    axis_values = unique(axis_values, 'sorted');
    return;
end
surface_table = local_getfield_or(surface_in, 'surface_table', table());
if istable(surface_table) && ismember(table_field, surface_table.Properties.VariableNames)
    axis_values = unique(surface_table.(table_field), 'sorted');
else
    axis_values = [];
end
end

function full_table = local_build_full_grid_table(surface_table, x_values, y_values, options)
base_fields = {'P', 'i_deg', 'num_total', 'num_feasible', 'feasible_ratio', 'minimum_feasible_Ns', 'best_joint_margin_at_min', 'minimum_support_sources', 'aesthetic_overcompute_touched', 'aesthetic_overcompute_status', 'frontier_refinement_touched', 'frontier_refinement_status'};
h_km = local_getfield_or(options, 'h_km', local_pick_table_scalar(surface_table, 'h_km', NaN));
family_name = string(local_getfield_or(options, 'family_name', local_pick_table_scalar(surface_table, 'family_name', "")));
if isfinite(h_km)
    base_fields = [{'h_km'}, base_fields];
end
if strlength(family_name) > 0
    base_fields = [{'family_name'}, base_fields];
end

rows = cell(numel(x_values) * numel(y_values), numel(base_fields));
cursor = 0;
for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        cursor = cursor + 1;
        row = local_default_row(base_fields, h_km, family_name, x_values(ix), y_values(iy));
        rows(cursor, :) = row;
    end
end
full_table = cell2table(rows, 'VariableNames', base_fields);
full_table = local_cast_default_columns(full_table);

if isempty(surface_table)
    return;
end

for idx = 1:height(surface_table)
    row_hit = find(abs(full_table.P - surface_table.P(idx)) < 1.0e-9 & abs(full_table.i_deg - surface_table.i_deg(idx)) < 1.0e-9, 1, 'first');
    if isempty(row_hit)
        continue;
    end
    copy_fields = intersect(surface_table.Properties.VariableNames, full_table.Properties.VariableNames, 'stable');
    for idx_field = 1:numel(copy_fields)
        full_table.(copy_fields{idx_field})(row_hit) = surface_table.(copy_fields{idx_field})(idx);
    end
end
end

function row = local_default_row(fields, h_km, family_name, p_value, i_value)
row = cell(1, numel(fields));
for idx = 1:numel(fields)
    switch fields{idx}
        case 'h_km'
            row{idx} = h_km;
        case 'family_name'
            row{idx} = family_name;
        case 'P'
            row{idx} = p_value;
        case 'i_deg'
            row{idx} = i_value;
        case {'num_total', 'num_feasible'}
            row{idx} = 0;
        case 'feasible_ratio'
            row{idx} = 0;
        case {'minimum_feasible_Ns', 'best_joint_margin_at_min'}
            row{idx} = NaN;
        case 'minimum_support_sources'
            row{idx} = "";
        case {'aesthetic_overcompute_touched', 'frontier_refinement_touched'}
            row{idx} = false;
        case {'aesthetic_overcompute_status', 'frontier_refinement_status'}
            row{idx} = "undefined";
        otherwise
            row{idx} = "";
    end
end
end

function T = local_cast_default_columns(T)
string_fields = intersect({'family_name', 'minimum_support_sources', 'aesthetic_overcompute_status', 'frontier_refinement_status'}, T.Properties.VariableNames, 'stable');
logical_fields = intersect({'aesthetic_overcompute_touched', 'frontier_refinement_touched'}, T.Properties.VariableNames, 'stable');
double_fields = setdiff(T.Properties.VariableNames, [string_fields, logical_fields], 'stable');
for idx = 1:numel(string_fields)
    T.(string_fields{idx}) = string(T.(string_fields{idx}));
end
for idx = 1:numel(logical_fields)
    T.(logical_fields{idx}) = logical(T.(logical_fields{idx}));
end
for idx = 1:numel(double_fields)
    if ~isnumeric(T.(double_fields{idx}))
        T.(double_fields{idx}) = double(T.(double_fields{idx}));
    end
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

function value = local_pick_table_scalar(T, field_name, fallback)
if istable(T) && ~isempty(T) && ismember(field_name, T.Properties.VariableNames)
    value = T.(field_name)(1);
else
    value = fallback;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
