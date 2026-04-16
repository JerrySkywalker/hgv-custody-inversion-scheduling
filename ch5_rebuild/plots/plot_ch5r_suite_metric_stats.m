function out = plot_ch5r_suite_metric_stats(summary_overall, metric, output_dir, visible_mode, tag)
%PLOT_CH5R_SUITE_METRIC_STATS
% Plot grouped bars for mean / q75 / max by method.

if nargin < 4 || isempty(visible_mode)
    visible_mode = 'off';
end
if nargin < 5 || isempty(tag)
    tag = char(datetime('now','Format','yyyyMMdd_HHmmss'));
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

method_labels = cellstr(string(summary_overall.method));

Y = [ ...
    summary_overall.([metric '_mean']), ...
    summary_overall.([metric '_q75']), ...
    summary_overall.([metric '_max'])];

fig = figure('Visible', visible_mode, 'Color', 'w', 'Position', [120 120 980 620]);
bar(Y, 'grouped');
grid on;
xticks(1:numel(method_labels));
xticklabels(method_labels);
xtickangle(12);
ylabel(strrep(metric, '_', '\_'), 'Interpreter', 'latex');
title([strrep(metric, '_', '\_') ' statistics by method'], 'Interpreter', 'latex');
legend({'mean','q75','max'}, 'Interpreter', 'latex', 'Location', 'best');

fig_file = fullfile(output_dir, ['phase4_metric_' metric '_' tag '.png']);
saveas(fig, fig_file);
close(fig);

out = struct();
out.metric = metric;
out.fig_file = fig_file;
end
