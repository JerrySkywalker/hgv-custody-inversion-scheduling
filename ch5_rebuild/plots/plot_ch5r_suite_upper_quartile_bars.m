function out = plot_ch5r_suite_upper_quartile_bars(summary_all, metric_base, outdir, visible_mode)
%PLOT_CH5R_SUITE_UPPER_QUARTILE_BARS
% Plot upper quartile mean bar chart with numeric labels.

if nargin < 2 || isempty(metric_base)
    metric_base = 'LoC_ratio';
end
if nargin < 3 || isempty(outdir)
    outdir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'multicase_suite', 'figs');
end
if nargin < 4 || isempty(visible_mode)
    visible_mode = 'off';
end

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

colname = [metric_base '_upper_quartile_mean'];
assert(ismember(colname, summary_all.Properties.VariableNames), 'Missing column: %s', colname);

method_order = {'R4','R5','R9','R10'};
methods_present = unique(cellstr(string(summary_all.method)), 'stable');
method_order = method_order(ismember(method_order, methods_present));

Y = nan(numel(method_order),1);
for i = 1:numel(method_order)
    m = method_order{i};
    idx = strcmp(string(summary_all.method), m);
    if any(idx)
        Y(i) = summary_all.(colname)(idx);
    end
end

fig = figure('Visible', visible_mode, 'Color', 'w');
ax = axes(fig);
bh = bar(ax, Y);
grid(ax, 'on');
xticks(ax, 1:numel(method_order));
xticklabels(ax, method_order);
xlabel(ax, 'Method');
ylabel(ax, [metric_base ' upper quartile mean'], 'Interpreter', 'none');
title(ax, [metric_base ' upper quartile mean'], 'Interpreter', 'none');

if all(isfinite(Y)) && all(Y >= 0)
    ylim(ax, [0, max(Y) + 0.06]);
end

annotate_ch5r_bar_values(ax, bh, '%.3f', struct('mode','above','font_size',9));

tag = lower(regexprep(metric_base, '[^A-Za-z0-9]+', '_'));
png_file = fullfile(outdir, ['ch5r_multicase_' tag '_upper_quartile_bar.png']);
fig_file = fullfile(outdir, ['ch5r_multicase_' tag '_upper_quartile_bar.fig']);
saveas(fig, png_file);
savefig(fig, fig_file);
close(fig);

out = struct('png_file', png_file, 'fig_file', fig_file);
end
