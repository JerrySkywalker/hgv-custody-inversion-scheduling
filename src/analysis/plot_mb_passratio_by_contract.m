function fig = plot_mb_passratio_by_contract(phasecurve_table, h_km, style, options, contract)
%PLOT_MB_PASSRATIO_BY_CONTRACT Plot MB pass-ratio curves using an explicit view contract.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 4 || isempty(options)
    options = struct();
end
if nargin < 5 || isempty(contract)
    contract = resolve_mb_plot_view_contract(local_getfield_or(options, 'runtime', struct()), struct( ...
        'passratio_mode', string(local_getfield_or(options, 'current_mode', ""))));
end

fig = create_managed_figure(local_getfield_or(options, 'runtime', struct()), 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

y_field = local_resolve_y_field(phasecurve_table);
guard = compute_mb_plot_window_from_data(local_get_table_column(phasecurve_table, 'Ns'), struct( ...
    'plot_xlim_ns', local_getfield_or(options, 'plot_xlim_ns', []), ...
    'search_domain_bounds', local_getfield_or(options, 'search_domain_bounds', []), ...
    'empty_message', 'No valid pass-ratio point found within current search domain'));

if isempty(phasecurve_table) || strlength(y_field) == 0
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No valid pass-ratio point found within current search domain', ...
        'domain_summary', sprintf('h = %.0f km', h_km), ...
        'plot_domain_source', guard.plot_domain_source, ...
        'figure_style', local_getfield_or(options, 'figure_style', struct())));
else
    unique_i = unique(phasecurve_table.i_deg, 'sorted');
    cmap = turbo(max(2, numel(unique_i)));
    base_grid_step = local_resolve_base_grid_step(phasecurve_table);
    gap_steps_for_break = max(1, double(local_getfield_or(options, 'passratio_gap_steps_for_break', 1)));
    break_long_gaps = logical(local_getfield_or(options, 'passratio_break_long_gaps', true));
    show_isolated = logical(local_getfield_or(options, 'passratio_show_scatter_for_isolated', true));
    if string(contract.view_name) == "historyFull"
        max_gap_for_connect = inf;
    elseif break_long_gaps && isfinite(base_grid_step) && base_grid_step > 0
        max_gap_for_connect = gap_steps_for_break * base_grid_step;
    else
        max_gap_for_connect = inf;
    end

    for idx = 1:numel(unique_i)
        sub = phasecurve_table(phasecurve_table.i_deg == unique_i(idx), :);
        sub = sortrows(sub, 'Ns');
        x_values = sub.Ns;
        y_values = sub.(char(y_field));
        is_defined = local_resolve_defined_mask(sub, y_field, contract);
        segments = build_mb_polyline_segments_from_defined_points(x_values, y_values, is_defined, max_gap_for_connect);
        display_name = sprintf('i = %.0f deg', unique_i(idx));
        display_consumed = false;
        isolated_mask = false(numel(x_values), 1);
        for idx_seg = 1:numel(segments)
            seg = segments{idx_seg};
            if isempty(seg.x)
                continue;
            end
            if numel(seg.x) == 1
                isolated_mask = isolated_mask | (abs(x_values - seg.x) < 1.0e-9 & abs(y_values - seg.y) < 1.0e-9);
                continue;
            end
            plot(ax, seg.x, seg.y, '-o', ...
                'Color', cmap(idx, :), ...
                'LineWidth', style.line_width, ...
                'MarkerSize', style.marker_size, ...
                'DisplayName', local_segment_label(display_name, display_consumed));
            display_consumed = true;
        end
        if show_isolated && any(isolated_mask)
            plot(ax, x_values(isolated_mask), y_values(isolated_mask), 'o', ...
                'Color', cmap(idx, :), ...
                'LineWidth', style.line_width, ...
                'MarkerSize', style.marker_size + 1, ...
                'MarkerFaceColor', cmap(idx, :), ...
                'DisplayName', local_segment_label(display_name + " (isolated)", display_consumed));
            display_consumed = true;
        end
        if ~display_consumed
            valid_mask = isfinite(x_values) & isfinite(y_values) & is_defined;
            if any(valid_mask)
                plot(ax, x_values(valid_mask), y_values(valid_mask), 'o', ...
                    'Color', cmap(idx, :), ...
                    'LineWidth', style.line_width, ...
                    'MarkerSize', style.marker_size + 1, ...
                    'MarkerFaceColor', cmap(idx, :), ...
                    'DisplayName', display_name);
            end
        end
    end
end

if isfield(options, 'required_pass_ratio') && isfinite(options.required_pass_ratio)
    yline(ax, options.required_pass_ratio, ':', ...
        'Color', style.colors(2, :), ...
        'LineWidth', style.threshold_line_width, ...
        'DisplayName', sprintf('Required pass ratio = %.2f', options.required_pass_ratio));
end

xlabel(ax, 'N_s');
ylabel(ax, 'Max pass ratio under fixed i');
title(ax, sprintf('Pass-Ratio Profile versus N_s at h = %.0f km', h_km));
apply_mb_plot_domain_guardrail(ax, local_get_table_column(phasecurve_table, 'Ns'), local_get_table_column(phasecurve_table, char(y_field)), struct( ...
    'plot_xlim_ns', local_getfield_or(options, 'plot_xlim_ns', []), ...
    'search_domain_bounds', local_getfield_or(options, 'search_domain_bounds', []), ...
    'ylim', local_resolve_ylim(options), ...
    'empty_message', 'No valid pass-ratio point found within current search domain', ...
    'domain_summary', sprintf('h = %.0f km', h_km), ...
    'plot_domain_source', guard.plot_domain_source, ...
    'figure_style', local_getfield_or(options, 'figure_style', struct())));
local_add_contract_annotation(ax, options, contract);
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Box', style.legend_box);
hold(ax, 'off');
end

function y_field = local_resolve_y_field(T)
y_field = "";
for field_name = ["max_pass_ratio", "overlay_pass_ratio", "max_pass_ratio_legacyDG", "max_pass_ratio_closedD"]
    if istable(T) && ismember(field_name, string(T.Properties.VariableNames))
        y_field = field_name;
        return;
    end
end
end

function is_defined = local_resolve_defined_mask(T, y_field, contract)
y_values = local_get_table_column(T, char(y_field));
if istable(T) && ismember('is_defined', T.Properties.VariableNames)
    is_defined = logical(T.is_defined);
else
    is_defined = isfinite(y_values);
end
if logical(contract.connect_only_defined)
    is_defined = is_defined & isfinite(y_values);
end
end

function step = local_resolve_base_grid_step(T)
step = NaN;
if istable(T) && ismember('base_grid_step', T.Properties.VariableNames)
    values = T.base_grid_step(isfinite(T.base_grid_step));
    if ~isempty(values)
        step = values(1);
        return;
    end
end
ns_values = unique(local_get_table_column(T, 'Ns'), 'sorted');
ns_values = ns_values(isfinite(ns_values));
if numel(ns_values) >= 2
    step = min(diff(ns_values));
end
end

function label = local_segment_label(base_label, display_consumed)
if display_consumed
    label = "";
else
    label = base_label;
end
end

function values = local_get_table_column(T, field_name)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
else
    values = [];
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function ylim_values = local_resolve_ylim(options)
if isfield(options, 'plot_ylim_passratio') && numel(options.plot_ylim_passratio) == 2 && all(isfinite(options.plot_ylim_passratio))
    ylim_values = reshape(options.plot_ylim_passratio, 1, []);
else
    ylim_values = [0, 1.05];
end
end

function local_add_contract_annotation(ax, options, contract)
style_mode = local_getfield_or(options, 'figure_style', struct());
if isstruct(style_mode) && isfield(style_mode, 'show_diagnostic_annotation') && ~logical(style_mode.show_diagnostic_annotation)
    return;
end
text_parts = strings(0, 1);
plot_domain_label = string(local_getfield_or(options, 'plot_domain_label', local_getfield_or(options, 'plot_domain_source', "")));
if strlength(plot_domain_label) > 0
    text_parts(end + 1, 1) = "plot-domain: " + plot_domain_label; %#ok<AGROW>
end
status_text = string(local_getfield_or(options, 'scope_annotation_text', ""));
if strlength(status_text) == 0 && logical(contract.is_effective_view)
    status_text = "status: effective domain only, not global";
elseif strlength(status_text) == 0 && logical(contract.is_global_view)
    status_text = "status: global replay from defined points only";
end
if strlength(status_text) > 0
    text_parts(end + 1, 1) = status_text; %#ok<AGROW>
end
if isfield(options, 'diagnostic_text') && strlength(string(options.diagnostic_text)) > 0
    text_parts(end + 1, 1) = string(options.diagnostic_text); %#ok<AGROW>
end
if isempty(text_parts)
    return;
end
annotation_text = strjoin(text_parts(1:min(end, 3)), newline);
text(ax, 0.02, 0.98, annotation_text, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 9.5, ...
    'Color', [0.35 0.35 0.35], ...
    'Interpreter', 'none');
end
