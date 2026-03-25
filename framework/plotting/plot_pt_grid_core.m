function [fig, ax, grid_data] = plot_pt_grid_core(tbl, p_col, t_col, value_col, opts)
if nargin < 5
    opts = struct();
end

assert(istable(tbl), 'plot_pt_grid_core:InvalidInput', 'tbl must be a table.');
assert(ismember(p_col, tbl.Properties.VariableNames), 'Missing P column.');
assert(ismember(t_col, tbl.Properties.VariableNames), 'Missing T column.');
assert(ismember(value_col, tbl.Properties.VariableNames), 'Missing value column.');

if ~isfield(opts, 'title_text'); opts.title_text = ''; end
if ~isfield(opts, 'x_label'); opts.x_label = 'T'; end
if ~isfield(opts, 'y_label'); opts.y_label = 'P'; end
if ~isfield(opts, 'show_text'); opts.show_text = true; end
if ~isfield(opts, 'text_format'); opts.text_format = '%.2g'; end
if ~isfield(opts, 'colorbar_label'); opts.colorbar_label = ''; end
if ~isfield(opts, 'nan_color'); opts.nan_color = [0.94 0.94 0.94]; end

P_vals = unique(tbl.(p_col));
T_vals = unique(tbl.(t_col));
P_vals = sort(P_vals(:));
T_vals = sort(T_vals(:));

V = nan(numel(P_vals), numel(T_vals));

for i = 1:height(tbl)
    p = tbl.(p_col)(i);
    t = tbl.(t_col)(i);
    v = tbl.(value_col)(i);

    ip = find(P_vals == p, 1);
    it = find(T_vals == t, 1);

    if ~isempty(ip) && ~isempty(it)
        V(ip, it) = v;
    end
end

fig = figure('Name', char(string(opts.title_text)));
ax = axes(fig);

imagesc(ax, T_vals, P_vals, V);
set(ax, 'YDir', 'normal');
xlabel(ax, opts.x_label);
ylabel(ax, opts.y_label);
title(ax, opts.title_text);

cb = colorbar(ax);
if ~isempty(opts.colorbar_label)
    ylabel(cb, opts.colorbar_label);
end

colormap(ax, parula);

if any(isnan(V), 'all')
    clim = caxis(ax);
    if any(isfinite(V), 'all')
        cmap = colormap(ax);
        cmap(1, :) = opts.nan_color;
        colormap(ax, cmap);
        caxis(ax, clim);
    end
end

xticks(ax, T_vals);
yticks(ax, P_vals);
grid(ax, 'on');
ax.GridAlpha = 0.15;

if opts.show_text
    for ip = 1:numel(P_vals)
        for it = 1:numel(T_vals)
            if ~isnan(V(ip, it))
                text(ax, T_vals(it), P_vals(ip), ...
                    sprintf(opts.text_format, V(ip, it)), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontSize', 9, ...
                    'Color', 'k');
            end
        end
    end
end

grid_data = struct();
grid_data.P_vals = P_vals;
grid_data.T_vals = T_vals;
grid_data.V = V;
end
