function [surface_out, rebuild_meta] = rebuild_mb_requirement_surface_for_heatmap(surface_in, search_domain, options)
%REBUILD_MB_REQUIREMENT_SURFACE_FOR_HEATMAP Rebuild a full global requirement surface for heatmap semantics.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

raw_eval_table = local_getfield_or(options, 'raw_eval_table', table());
x_values = reshape(local_getfield_or(options, 'x_values', []), 1, []);
y_values = reshape(local_getfield_or(options, 'y_values', []), 1, []);
if isempty(x_values)
    x_values = local_resolve_axis_values(search_domain, surface_in, 'global_P_grid', 'P_grid', 'x_values', 'P');
end
if isempty(y_values)
    y_values = local_resolve_axis_values(search_domain, surface_in, 'global_inclination_grid_deg', 'inclination_grid_deg', 'y_values', 'i_deg');
end

surface_out = surface_in;
rebuild_meta = struct( ...
    'used_global_rebuild', false, ...
    'used_skeleton_projection', true, ...
    'num_defined_cells', 0, ...
    'num_nan_cells', 0, ...
    'source_table_kind', "surface_table_projection");

if isempty(x_values) || isempty(y_values)
    return;
end

rebuilt_surface_table = table();
if ~isempty(raw_eval_table)
    rebuilt_surface = build_mb_requirement_surface(raw_eval_table, 'P', 'i_deg');
    rebuilt_surface_table = local_getfield_or(rebuilt_surface, 'surface_table', table());
    rebuild_meta.used_global_rebuild = true;
    rebuild_meta.used_skeleton_projection = false;
    rebuild_meta.source_table_kind = "raw_eval_table_requirement_surface";
end

provenance_table = local_getfield_or(surface_in, 'surface_table', table());
full_table = local_build_full_grid_table(rebuilt_surface_table, provenance_table, x_values, y_values, options);

surface_out.surface_table = full_table;
surface_out.x_values = x_values(:);
surface_out.y_values = y_values(:);
surface_out.value_matrix = local_build_value_matrix(full_table, x_values, y_values, 'minimum_feasible_Ns');
surface_out.numeric_requirement_matrix = surface_out.value_matrix;
surface_out.margin_matrix = local_build_value_matrix(full_table, x_values, y_values, 'best_joint_margin_at_min');
surface_out.surface_name = string(local_getfield_or(surface_in, 'surface_name', "requirement_surface")) + "_globalReplay";
surface_out.heatmap_surface_mode = "globalReplay";
surface_out.matrix_domain_source = "global_i_p_requirement_rebuild";
surface_out.global_skeleton_applied = true;
surface_out.used_global_rebuild = rebuild_meta.used_global_rebuild;
surface_out.used_skeleton_projection = rebuild_meta.used_skeleton_projection;
surface_out.surface_rebuild_policy = "true_global_requirement_surface";

defined_mask = isfinite(surface_out.numeric_requirement_matrix);
rebuild_meta.num_defined_cells = sum(defined_mask(:));
rebuild_meta.num_nan_cells = sum(~defined_mask(:));
surface_out.num_defined_cells = rebuild_meta.num_defined_cells;
surface_out.num_nan_cells = rebuild_meta.num_nan_cells;
surface_out.heatmap_global_grid_coverage_ratio = local_safe_ratio(rebuild_meta.num_defined_cells, rebuild_meta.num_defined_cells + rebuild_meta.num_nan_cells);
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

function full_table = local_build_full_grid_table(base_surface_table, provenance_table, x_values, y_values, options)
base_fields = {'P', 'i_deg', 'num_total', 'num_feasible', 'feasible_ratio', 'minimum_feasible_Ns', 'best_joint_margin_at_min', 'minimum_support_sources', 'aesthetic_overcompute_touched', 'aesthetic_overcompute_status', 'frontier_refinement_touched', 'frontier_refinement_status', 'coverage_state'};
h_km = local_getfield_or(options, 'h_km', local_pick_table_scalar(base_surface_table, 'h_km', local_pick_table_scalar(provenance_table, 'h_km', NaN)));
family_name = string(local_getfield_or(options, 'family_name', local_pick_table_scalar(base_surface_table, 'family_name', local_pick_table_scalar(provenance_table, 'family_name', ""))));
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
        rows(cursor, :) = local_default_row(base_fields, h_km, family_name, x_values(ix), y_values(iy));
    end
end
full_table = cell2table(rows, 'VariableNames', base_fields);
full_table = local_cast_default_columns(full_table);
full_table = local_copy_surface_rows(full_table, base_surface_table);
full_table = local_copy_provenance_rows(full_table, provenance_table);
full_table = local_finalize_coverage_state(full_table);
end

function full_table = local_copy_surface_rows(full_table, base_surface_table)
if isempty(base_surface_table)
    return;
end
copy_fields = intersect(base_surface_table.Properties.VariableNames, full_table.Properties.VariableNames, 'stable');
for idx = 1:height(base_surface_table)
    row_hit = find(abs(full_table.P - base_surface_table.P(idx)) < 1.0e-9 & abs(full_table.i_deg - base_surface_table.i_deg(idx)) < 1.0e-9, 1, 'first');
    if isempty(row_hit)
        continue;
    end
    for idx_field = 1:numel(copy_fields)
        full_table.(copy_fields{idx_field})(row_hit) = base_surface_table.(copy_fields{idx_field})(idx);
    end
end
end

function full_table = local_copy_provenance_rows(full_table, provenance_table)
if isempty(provenance_table)
    return;
end
copy_fields = intersect({'aesthetic_overcompute_touched', 'aesthetic_overcompute_status', 'frontier_refinement_touched', 'frontier_refinement_status', 'minimum_support_sources'}, provenance_table.Properties.VariableNames, 'stable');
for idx = 1:height(provenance_table)
    row_hit = find(abs(full_table.P - provenance_table.P(idx)) < 1.0e-9 & abs(full_table.i_deg - provenance_table.i_deg(idx)) < 1.0e-9, 1, 'first');
    if isempty(row_hit)
        continue;
    end
    for idx_field = 1:numel(copy_fields)
        full_table.(copy_fields{idx_field})(row_hit) = provenance_table.(copy_fields{idx_field})(idx);
    end
end
end

function full_table = local_finalize_coverage_state(full_table)
for idx = 1:height(full_table)
    num_total = local_pick_table_scalar(full_table(idx, :), 'num_total', 0);
    min_ns = local_pick_table_scalar(full_table(idx, :), 'minimum_feasible_Ns', NaN);
    if num_total <= 0
        full_table.coverage_state(idx) = "uncomputed";
    elseif isfinite(min_ns)
        full_table.coverage_state(idx) = "defined";
    else
        full_table.coverage_state(idx) = "evaluated_infeasible";
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
            row{idx} = NaN;
        case {'minimum_feasible_Ns', 'best_joint_margin_at_min'}
            row{idx} = NaN;
        case 'minimum_support_sources'
            row{idx} = "";
        case {'aesthetic_overcompute_touched', 'frontier_refinement_touched'}
            row{idx} = false;
        case {'aesthetic_overcompute_status', 'frontier_refinement_status'}
            row{idx} = "undefined";
        case 'coverage_state'
            row{idx} = "uncomputed";
        otherwise
            row{idx} = "";
    end
end
end

function T = local_cast_default_columns(T)
string_fields = intersect({'family_name', 'minimum_support_sources', 'aesthetic_overcompute_status', 'frontier_refinement_status', 'coverage_state'}, T.Properties.VariableNames, 'stable');
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

function value = local_safe_ratio(num, den)
if ~(isnumeric(num) && isnumeric(den)) || ~isscalar(num) || ~isscalar(den) || den <= 0
    value = NaN;
    return;
end
value = double(num) / double(den);
end
