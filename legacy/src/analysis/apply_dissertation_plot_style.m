function style = apply_dissertation_plot_style(fig, style)
%APPLY_DISSERTATION_PLOT_STYLE Apply dissertation-facing figure defaults.

if nargin < 1
    fig = [];
end
if nargin < 2 || isempty(style)
    style = milestone_common_plot_style();
end

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');

if isempty(fig) || ~ishandle(fig)
    return;
end

set(fig, 'Color', 'w');

axes_list = findall(fig, 'Type', 'axes');
for k = 1:numel(axes_list)
    ax = axes_list(k);
    set(ax, ...
        'FontSize', style.font_size, ...
        'LineWidth', style.axis_line_width, ...
        'Box', 'on', ...
        'Layer', 'top');
    grid(ax, 'on');
end

legend_list = findall(fig, 'Type', 'legend');
for k = 1:numel(legend_list)
    lgd = legend_list(k);
    set(lgd, 'Box', style.legend_box);
end
end
