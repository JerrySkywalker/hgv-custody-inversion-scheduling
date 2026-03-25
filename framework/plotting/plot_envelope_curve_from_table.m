function [fig, ax] = plot_envelope_curve_from_table(tbl, x_col, y_col, opts)
%PLOT_ENVELOPE_CURVE_FROM_TABLE Plot a grouped curve from a table.

if nargin < 4 || isempty(opts)
    opts = struct();
end

[fig, ax] = plot_xy_curve_core(tbl, x_col, y_col, opts);
end
