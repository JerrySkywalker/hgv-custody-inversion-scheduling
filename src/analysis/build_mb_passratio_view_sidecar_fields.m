function extra_fields = build_mb_passratio_view_sidecar_fields(fig, source_table, source_path, domain_view, resolved_xlim, view_meta, spec)
%BUILD_MB_PASSRATIO_VIEW_SIDECAR_FIELDS Build consistent sidecar metadata for pass-ratio views.

if nargin < 7 || isempty(spec)
    spec = struct();
end
if nargin < 6 || isempty(view_meta)
    view_meta = struct();
end

actual_xlim = reshape(local_getfield_or(spec, 'rendered_xlim', [NaN, NaN]), 1, []);
if ~all(isfinite(actual_xlim))
    actual_xlim = capture_mb_primary_axes_xlim(fig);
end
signature = build_mb_figure_signature(struct( ...
    'figure_family', string(local_getfield_or(spec, 'figure_family', "passratio_view")), ...
    'plot_domain_mode', string(domain_view), ...
    'domain_view', string(domain_view), ...
    'plot_xlim_ns', reshape(resolved_xlim, 1, []), ...
    'plot_ylim_passratio', reshape(local_getfield_or(spec, 'plot_ylim_passratio', []), 1, []), ...
    'figure_style_mode', string(local_getfield_or(spec, 'figure_style_mode', "")), ...
    'export_paper_ready', logical(local_getfield_or(spec, 'export_paper_ready', false)), ...
    'plotting_mode', string(local_getfield_or(spec, 'plotting_mode', "")), ...
    'renderer', string(local_getfield_or(spec, 'renderer', "")), ...
    'export_dpi', local_getfield_or(spec, 'export_dpi', NaN), ...
    'figure_version', string(local_getfield_or(spec, 'figure_version', "mb-figure-v1")), ...
    'history_padding_applied', logical(local_getfield_or(view_meta, 'history_padding_applied', false)), ...
    'history_fill_mode', string(local_getfield_or(view_meta, 'history_fill_mode', "")), ...
    'history_origin', string(local_getfield_or(view_meta, 'history_origin', ""))));

fallback_override_applied = false;
fallback_override_source = "";
if all(isfinite(actual_xlim)) && all(isfinite(resolved_xlim)) && any(abs(actual_xlim - resolved_xlim) > 1.0e-9)
    fallback_override_applied = true;
    fallback_override_source = "axis_guardrail";
end

extra_fields = struct();
extra_fields.phasecurve_source_file_or_table = string(source_path);
extra_fields.phasecurve_cache_hit = false;
extra_fields.phasecurve_cache_key = string(signature);
extra_fields.source_table_min_ns = double(local_getfield_or(view_meta, 'source_table_min_ns', local_min_table_value(source_table, 'Ns')));
extra_fields.source_table_max_ns = double(local_getfield_or(view_meta, 'source_table_max_ns', local_max_table_value(source_table, 'Ns')));
extra_fields.source_table_row_count = double(local_getfield_or(view_meta, 'source_table_row_count', height(source_table)));
extra_fields.history_padding_applied = logical(local_getfield_or(view_meta, 'history_padding_applied', false));
extra_fields.history_padding_mode = string(local_getfield_or(view_meta, 'history_fill_mode', ""));
extra_fields.history_origin = string(local_getfield_or(view_meta, 'history_origin', ""));
extra_fields.resolver_xlim_min = double(local_pick_x(resolved_xlim, 1));
extra_fields.resolver_xlim_max = double(local_pick_x(resolved_xlim, 2));
extra_fields.fallback_override_applied = logical(fallback_override_applied);
extra_fields.fallback_override_source = string(fallback_override_source);
extra_fields.actual_rendered_xlim_min = double(local_pick_x(actual_xlim, 1));
extra_fields.actual_rendered_xlim_max = double(local_pick_x(actual_xlim, 2));
extra_fields.expected_domain_behavior = string(local_getfield_or(spec, 'expected_domain_behavior', ""));
extra_fields.actual_domain_behavior = string(local_getfield_or(spec, 'actual_domain_behavior', ""));
extra_fields.root_cause_tag = string(local_getfield_or(view_meta, 'root_cause_tag', "correct"));
extra_fields.plot_primary_mode = string(local_getfield_or(spec, 'primary_plot_mode', ""));
extra_fields.canonical_primary_mode = string(local_getfield_or(spec, 'canonical_primary_mode', ""));
extra_fields.current_plot_mode = string(local_getfield_or(spec, 'current_mode', ""));
extra_fields.is_primary_mode = logical(local_getfield_or(spec, 'is_primary_selection', false));
extra_fields.is_canonical_selection = logical(local_getfield_or(spec, 'is_canonical_selection', false));
extra_fields.canonical_figure_file = string(local_getfield_or(spec, 'canonical_figure_file', ""));
end

function value = local_pick_x(xlim_values, idx_pick)
value = NaN;
if isnumeric(xlim_values) && numel(xlim_values) >= idx_pick && isfinite(xlim_values(idx_pick))
    value = xlim_values(idx_pick);
end
end

function value = local_min_table_value(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
values = T.(field_name);
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function value = local_max_table_value(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
values = T.(field_name);
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
