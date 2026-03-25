function [fig, ax, grid_data] = plot_heatmap_from_table(tbl, value_col, opts)
%PLOT_HEATMAP_FROM_TABLE Plot a P-T heatmap from a table.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'p_col'); opts.p_col = 'P'; end
if ~isfield(opts, 't_col'); opts.t_col = 'T'; end

[fig, ax, grid_data] = plot_pt_grid_core(tbl, opts.p_col, opts.t_col, value_col, opts);
end
