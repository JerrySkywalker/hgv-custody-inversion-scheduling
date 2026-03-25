function [fig, ax] = plot_xy_curve_core(tbl, x_col, y_col, opts)
if nargin < 4
    opts = struct();
end

assert(istable(tbl), 'plot_xy_curve_core:InvalidInput', 'tbl must be a table.');
assert(ismember(x_col, tbl.Properties.VariableNames), 'Missing x column.');
assert(ismember(y_col, tbl.Properties.VariableNames), 'Missing y column.');

if ~isfield(opts, 'title_text'); opts.title_text = ''; end
if ~isfield(opts, 'x_label'); opts.x_label = x_col; end
if ~isfield(opts, 'y_label'); opts.y_label = y_col; end
if ~isfield(opts, 'marker'); opts.marker = 'o'; end
if ~isfield(opts, 'line_width'); opts.line_width = 1.5; end
if ~isfield(opts, 'show_grid'); opts.show_grid = true; end
if ~isfield(opts, 'show_text'); opts.show_text = false; end
if ~isfield(opts, 'text_format'); opts.text_format = '%.2g'; end

x = tbl.(x_col);
y = tbl.(y_col);

[x_sorted, idx] = sort(x);
y_sorted = y(idx);

fig = figure('Name', char(string(opts.title_text)));
ax = axes(fig);

plot(ax, x_sorted, y_sorted, ...
    'LineWidth', opts.line_width, ...
    'Marker', opts.marker);

xlabel(ax, opts.x_label);
ylabel(ax, opts.y_label);
title(ax, opts.title_text);

if opts.show_grid
    grid(ax, 'on');
end

if opts.show_text
    for i = 1:numel(x_sorted)
        text(ax, x_sorted(i), y_sorted(i), ...
            sprintf(opts.text_format, y_sorted(i)), ...
            'VerticalAlignment', 'bottom', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 9);
    end
end
end
