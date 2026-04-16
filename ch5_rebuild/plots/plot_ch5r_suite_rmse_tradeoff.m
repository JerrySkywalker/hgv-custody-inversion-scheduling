function out = plot_ch5r_suite_rmse_tradeoff(summary_all, outdir, visible_mode)
%PLOT_CH5R_SUITE_RMSE_TRADEOFF
% Plot trade-off scatter:
%   x = LoC_ratio_mean
%   y = mean_rmse_pos_km_mean
%
% Also annotate method names and values.

if nargin < 2 || isempty(outdir)
    outdir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'multicase_suite', 'figs');
end
if nargin < 3 || isempty(visible_mode)
    visible_mode = 'off';
end

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

required = {'method','LoC_ratio_mean','mean_rmse_pos_km_mean','final_rmse_pos_km_mean'};
for i = 1:numel(required)
    assert(ismember(required{i}, summary_all.Properties.VariableNames), ...
        'Missing column: %s', required{i});
end

method_order = {'R4','R5','R9','R10'};
methods_present = unique(cellstr(string(summary_all.method)), 'stable');
method_order = method_order(ismember(method_order, methods_present));

x = nan(numel(method_order),1);
y = nan(numel(method_order),1);
y2 = nan(numel(method_order),1);

for i = 1:numel(method_order)
    m = method_order{i};
    idx = strcmp(string(summary_all.method), m);
    if any(idx)
        x(i)  = summary_all.LoC_ratio_mean(idx);
        y(i)  = summary_all.mean_rmse_pos_km_mean(idx);
        y2(i) = summary_all.final_rmse_pos_km_mean(idx);
    end
end

fig = figure('Visible', visible_mode, 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');
grid(ax, 'on');

scatter(ax, x, y, 70, ...
    'o', ...
    'MarkerFaceColor', [0.20 0.45 0.70], ...
    'MarkerEdgeColor', [0.20 0.45 0.70], ...
    'DisplayName', 'Method');

for i = 1:numel(method_order)
    if ~isfinite(x(i)) || ~isfinite(y(i))
        continue;
    end
    txt = sprintf('%s  (LoC=%.3f, meanRMSE=%.3f, finalRMSE=%.3f)', ...
        method_order{i}, x(i), y(i), y2(i));
    text(ax, x(i), y(i), ['  ' txt], ...
        'FontSize', 9, ...
        'Interpreter', 'none', ...
        'VerticalAlignment', 'bottom', ...
        'HorizontalAlignment', 'left');
end

xlabel(ax, 'LoC ratio mean');
ylabel(ax, 'Mean RMSE pos (km) mean');
title(ax, 'LoC-RMSE trade-off');

if all(isfinite(x)) && all(x >= 0)
    xlim(ax, [0, max(x) * 1.15 + 0.02]);
end
if all(isfinite(y)) && all(y >= 0)
    ylim(ax, [0, max(y) * 1.15 + 0.02]);
end

legend(ax, 'Location', 'best');

png_file = fullfile(outdir, 'ch5r_multicase_loc_rmse_tradeoff_scatter.png');
fig_file = fullfile(outdir, 'ch5r_multicase_loc_rmse_tradeoff_scatter.fig');
saveas(fig, png_file);
savefig(fig, fig_file);
close(fig);

out = struct('png_file', png_file, 'fig_file', fig_file);
end
