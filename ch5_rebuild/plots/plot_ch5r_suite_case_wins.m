function out = plot_ch5r_suite_case_wins(wins_overall, wins_by_family, outdir, visible_mode)
%PLOT_CH5R_SUITE_CASE_WINS
% Plot case-wise winner counts with numeric annotations.

if nargin < 3 || isempty(outdir)
    outdir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'multicase_suite', 'figs');
end
if nargin < 4 || isempty(visible_mode)
    visible_mode = 'off';
end

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

method_order = {'R4','R5','R9','R10'};
methods_present = unique(cellstr(string(wins_overall.method)), 'stable');
method_order = method_order(ismember(method_order, methods_present));

fig = figure('Visible', visible_mode, 'Color', 'w');
tl = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% overall
nexttile;
ax1 = gca;
Y = nan(numel(method_order), 2);
for i = 1:numel(method_order)
    m = method_order{i};
    idx = strcmp(string(wins_overall.method), m);
    if any(idx)
        Y(i,1) = wins_overall.raw_win_count(idx);
        Y(i,2) = wins_overall.fractional_win_count(idx);
    end
end
bh1 = bar(ax1, Y, 'grouped');
grid(ax1, 'on');
xticks(ax1, 1:numel(method_order));
xticklabels(ax1, method_order);
xlabel(ax1, 'Method');
ylabel(ax1, 'Win count');
title(ax1, 'Overall wins');
legend(ax1, {'Raw wins','Fractional wins'}, 'Location', 'eastoutside');
ylim(ax1, [0, max(Y(:)) + 0.35]);
annotate_ch5r_bar_values(ax1, bh1(1), '%.0f', struct('mode','above','font_size',9));
annotate_ch5r_bar_values(ax1, bh1(2), '%.1f', struct('mode','above','font_size',9));

% by family
nexttile;
ax2 = gca;
families = unique(cellstr(string(wins_by_family.family)), 'stable');
Yf = nan(numel(method_order), numel(families));
for j = 1:numel(families)
    f = families{j};
    for i = 1:numel(method_order)
        m = method_order{i};
        idx = strcmp(string(wins_by_family.method), m) & strcmp(string(wins_by_family.family), f);
        if any(idx)
            Yf(i,j) = wins_by_family.raw_win_count(idx);
        end
    end
end
bh2 = bar(ax2, Yf, 'grouped');
grid(ax2, 'on');
xticks(ax2, 1:numel(method_order));
xticklabels(ax2, method_order);
xlabel(ax2, 'Method');
ylabel(ax2, 'Raw win count');
title(ax2, 'Wins by family');
legend(ax2, families, 'Location', 'eastoutside');
ylim(ax2, [0, max(Yf(:)) + 0.25]);

for j = 1:numel(bh2)
    annotate_ch5r_bar_values(ax2, bh2(j), '%.0f', struct('mode','above','font_size',9));
end

title(tl, 'Case-wise winner statistics');

png_file = fullfile(outdir, 'ch5r_multicase_case_wins_bar.png');
fig_file = fullfile(outdir, 'ch5r_multicase_case_wins_bar.fig');
saveas(fig, png_file);
savefig(fig, fig_file);
close(fig);

out = struct('png_file', png_file, 'fig_file', fig_file);
end
