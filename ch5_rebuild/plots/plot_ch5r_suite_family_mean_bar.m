function out = plot_ch5r_suite_family_mean_bar(summary_by_family, metric, output_dir, visible_mode, tag)
%PLOT_CH5R_SUITE_FAMILY_MEAN_BAR
% Plot family-grouped mean bars by method.

if nargin < 4 || isempty(visible_mode)
    visible_mode = 'off';
end
if nargin < 5 || isempty(tag)
    tag = char(datetime('now','Format','yyyyMMdd_HHmmss'));
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

method_order = unique(cellstr(string(summary_by_family.method)), 'stable');
family_order = unique(cellstr(string(summary_by_family.family)), 'stable');

Y = nan(numel(method_order), numel(family_order));

for i = 1:numel(method_order)
    for j = 1:numel(family_order)
        idx = strcmpi(string(summary_by_family.method), method_order{i}) & ...
              strcmpi(string(summary_by_family.family), family_order{j});
        if any(idx)
            Y(i,j) = summary_by_family{find(idx,1,'first'), [metric '_mean']};
        end
    end
end

fig = figure('Visible', visible_mode, 'Color', 'w', 'Position', [120 120 980 620]);
bar(Y, 'grouped');
grid on;
xticks(1:numel(method_order));
xticklabels(method_order);
xtickangle(12);
ylabel([strrep(metric, '_', '\_') ' mean'], 'Interpreter', 'latex');
title([strrep(metric, '_', '\_') ' family mean comparison'], 'Interpreter', 'latex');
legend(family_order, 'Interpreter', 'latex', 'Location', 'best');

fig_file = fullfile(output_dir, ['phase4_family_' metric '_' tag '.png']);
saveas(fig, fig_file);
close(fig);

out = struct();
out.metric = metric;
out.fig_file = fig_file;
end
