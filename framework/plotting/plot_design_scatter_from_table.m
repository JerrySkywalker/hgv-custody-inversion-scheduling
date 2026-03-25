function [fig, ax] = plot_design_scatter_from_table(tbl, x_col, y_col, opts)
%PLOT_DESIGN_SCATTER_FROM_TABLE Plot a design-point scatter with optional labels.

if nargin < 4 || isempty(opts)
    opts = struct();
end

assert(istable(tbl), 'plot_design_scatter_from_table:InvalidInput', ...
    'tbl must be a table.');

if ~isfield(opts, 'title_text'); opts.title_text = ''; end
if ~isfield(opts, 'x_label'); opts.x_label = x_col; end
if ~isfield(opts, 'y_label'); opts.y_label = y_col; end
if ~isfield(opts, 'show_grid'); opts.show_grid = true; end
if ~isfield(opts, 'show_text'); opts.show_text = true; end
if ~isfield(opts, 'label_col'); opts.label_col = 'point_label'; end

x = tbl.(x_col);
y = tbl.(y_col);

fig = figure('Name', char(string(opts.title_text)));
ax = axes(fig);
scatter(ax, x, y, 48, 'filled');
xlabel(ax, opts.x_label);
ylabel(ax, opts.y_label);
title(ax, opts.title_text);

if opts.show_grid
    grid(ax, 'on');
end

if opts.show_text && ismember(opts.label_col, tbl.Properties.VariableNames)
    labels = string(tbl.(opts.label_col));
    for k = 1:height(tbl)
        text(ax, x(k), y(k), labels(k), ...
            'VerticalAlignment', 'bottom', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 9);
    end
end
end
