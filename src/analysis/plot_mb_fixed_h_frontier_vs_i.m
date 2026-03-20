function fig = plot_mb_fixed_h_frontier_vs_i(frontier_table, h_km, style, options)
%PLOT_MB_FIXED_H_FRONTIER_VS_I Plot the fixed-height minimum-feasible inclination frontier.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end
if nargin < 4 || isempty(options)
    options = struct();
end

fig = figure('Visible', 'off', 'Color', 'w');
setappdata(fig, 'mb_figure_style', local_getfield_or(options, 'figure_style', struct()));
ax = axes(fig);
hold(ax, 'on');

valid_frontier = ~isempty(frontier_table) && ismember('minimum_feasible_Ns', frontier_table.Properties.VariableNames) && ...
    any(isfinite(frontier_table.minimum_feasible_Ns));

if ~valid_frontier
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No feasible point found within current search domain', ...
        'domain_summary', sprintf('h = %.0f km', h_km), ...
        'plot_domain_source', "no_valid_frontier", ...
        'figure_style', local_getfield_or(options, 'figure_style', struct())));
else
    frontier_table = frontier_table(isfinite(frontier_table.i_deg) & isfinite(frontier_table.minimum_feasible_Ns), :);
    if numel(unique(frontier_table.i_deg)) < 2
        plot(ax, frontier_table.i_deg, frontier_table.minimum_feasible_Ns, 'o', ...
            'Color', style.colors(1, :), ...
            'LineWidth', style.line_width, ...
            'MarkerSize', style.marker_size + 2, ...
            'MarkerFaceColor', style.colors(1, :));
    else
        plot(ax, frontier_table.i_deg, frontier_table.minimum_feasible_Ns, '-o', ...
            'Color', style.colors(1, :), ...
            'LineWidth', style.line_width, ...
            'MarkerSize', style.marker_size + 1, ...
            'MarkerFaceColor', style.colors(1, :));
    end
    if local_show_annotations(options)
        for idx = 1:height(frontier_table)
            text(ax, frontier_table.i_deg(idx), frontier_table.minimum_feasible_Ns(idx) + 0.8, ...
                sprintf('%d', round(frontier_table.minimum_feasible_Ns(idx))), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 10, ...
                'FontWeight', 'bold', ...
                'Color', style.threshold_color);
        end
    end
end

xlabel(ax, 'i (deg)');
ylabel(ax, 'Minimum feasible N_s');
title(ax, sprintf('Inclination Frontier of Minimum Feasible Constellation Size at h = %.0f km', h_km));
grid(ax, 'on');
apply_mb_plot_domain_guardrail(ax, local_getfield_or(frontier_table, 'i_deg', []), local_getfield_or(frontier_table, 'minimum_feasible_Ns', []), struct( ...
    'min_span', 10, ...
    'auto_ylim', true, ...
    'empty_message', 'No feasible point found within current search domain', ...
    'domain_summary', sprintf('h = %.0f km', h_km), ...
    'plot_domain_source', "frontier_guardrail", ...
    'figure_style', local_getfield_or(options, 'figure_style', struct())));
local_add_frontier_note(ax, local_getfield_or(options, 'frontier_truncation_table', table()));
hold(ax, 'off');
end

function local_add_frontier_note(ax, truncation_table)
fig = ancestor(ax, 'figure');
style_mode = getappdata(fig, 'mb_figure_style');
if isstruct(style_mode) && isfield(style_mode, 'show_diagnostic_annotation') && ~logical(style_mode.show_diagnostic_annotation)
    return;
end
if isempty(truncation_table) || ~istable(truncation_table) || ~ismember('diagnostic_note', truncation_table.Properties.VariableNames)
    return;
end
notes = unique(string(truncation_table.diagnostic_note));
notes = notes(strlength(notes) > 0);
if isempty(notes)
    return;
end
text(ax, 0.02, 0.90, char(strjoin(notes, newline)), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontSize', 9.5, 'Color', [0.55 0.15 0.15]);
end

function values = local_getfield_or(T, field_name, fallback)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
elseif isstruct(T) && isfield(T, field_name)
    values = T.(field_name);
else
    values = fallback;
end
end

function tf = local_show_annotations(options)
style_mode = local_getfield_or(options, 'figure_style', struct());
if isstruct(style_mode) && isfield(style_mode, 'show_diagnostic_annotation')
    tf = logical(style_mode.show_diagnostic_annotation);
else
    tf = true;
end
end
