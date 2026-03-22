function extra_fields = build_mb_heatmap_sidecar_fields(surface, heatmap_mode, domain_mode, extra_fields)
%BUILD_MB_HEATMAP_SIDECAR_FIELDS Build consistent sidecar metadata for MB heatmap exports.

if nargin < 4 || isempty(extra_fields)
    extra_fields = struct();
end

heatmap_mode = string(heatmap_mode);
domain_mode = string(domain_mode);
if heatmap_mode == "state_map"
    matrix_source_name = string(local_getfield_or(surface, 'state_matrix_source_name', "discrete_state_matrix"));
    matrix_value_type = "discrete_state";
    uses_discrete_state_matrix = true;
    uses_numeric_requirement_matrix = false;
    annotation_mode = string(local_getfield_or(surface, 'annotation_mode_state', "state_only"));
    heatmap_value_semantics = "state_map_discrete";
else
    matrix_source_name = string(local_getfield_or(surface, 'numeric_matrix_source_name', "numeric_requirement_matrix"));
    matrix_value_type = "numeric_requirement";
    uses_discrete_state_matrix = false;
    uses_numeric_requirement_matrix = true;
    annotation_mode = string(local_getfield_or(surface, 'annotation_mode_numeric', "numeric_labels"));
    heatmap_value_semantics = "minimum_feasible_ns";
end

cache_key = build_mb_figure_signature(struct( ...
    'figure_family', "heatmap", ...
    'heatmap_view', heatmap_mode, ...
    'heatmap_domain_view', domain_mode, ...
    'matrix_source_type', matrix_value_type));

extra_fields.heatmap_mode = heatmap_mode;
extra_fields.heatmap_surface_mode = domain_mode;
extra_fields.heatmap_surface_source = string(local_getfield_or(surface, 'matrix_domain_source', ""));
extra_fields.heatmap_value_semantics = heatmap_value_semantics;
extra_fields.matrix_source_name = matrix_source_name;
extra_fields.matrix_value_type = matrix_value_type;
extra_fields.uses_discrete_state_matrix = logical(uses_discrete_state_matrix);
extra_fields.uses_numeric_requirement_matrix = logical(uses_numeric_requirement_matrix);
extra_fields.annotation_mode = annotation_mode;
extra_fields.height_km = double(local_getfield_or(surface, 'h_km', NaN));
extra_fields.h_km = double(local_getfield_or(surface, 'h_km', NaN));
extra_fields.heatmap_cache_hit = false;
extra_fields.heatmap_cache_key = string(cache_key);
extra_fields.cache_hit = false;
extra_fields.cache_key = string(cache_key);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
