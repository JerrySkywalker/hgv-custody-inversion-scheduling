function out = plot_ch5r_suite_family_state_bars(summary_by_family, outdir, visible_mode)
%PLOT_CH5R_SUITE_FAMILY_STATE_BARS
% Plot family-wise mean SC/DC/LoC occupancy with in-bar labels.

if nargin < 2 || isempty(outdir)
    outdir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'multicase_suite', 'figs');
end
if nargin < 3 || isempty(visible_mode)
    visible_mode = 'off';
end

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

T = summary_by_family;
assert(ismember('SC_ratio_mean', T.Properties.VariableNames), 'Missing SC_ratio_mean');
assert(ismember('DC_ratio_mean', T.Properties.VariableNames), 'Missing DC_ratio_mean');
assert(ismember('LoC_ratio_mean', T.Properties.VariableNames), 'Missing LoC_ratio_mean');

method_order = {'R4','R5','R9','R10'};
methods_present = unique(cellstr(string(T.method)), 'stable');
method_order = method_order(ismember(method_order, methods_present));

family_order = {'nominal','heading','critical'};
families_present = unique(cellstr(string(T.family)), 'stable');
family_order = family_order(ismember(family_order, families_present));

fig = figure('Visible', visible_mode, 'Color', 'w');
tl = tiledlayout(1, numel(family_order), 'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:numel(family_order)
    f = family_order{i};
    nexttile;
    ax = gca;

    idx = strcmp(string(T.family), f);
    S = T(idx, :);

    Y = nan(numel(method_order), 3);
    for j = 1:numel(method_order)
        m = method_order{j};
        idm = strcmp(string(S.method), m);
        if any(idm)
            Y(j,1) = S.SC_ratio_mean(idm);
            Y(j,2) = S.DC_ratio_mean(idm);
            Y(j,3) = S.LoC_ratio_mean(idm);
        end
    end

    bh = bar(ax, Y, 'stacked');
    ylim(ax, [0, 1.08]);
    grid(ax, 'on');
    xticks(ax, 1:numel(method_order));
    xticklabels(ax, method_order);
    xlabel(ax, 'Method');
    ylabel(ax, 'Mean ratio');
    title(ax, f, 'Interpreter', 'none');

    % segment annotations
    annotate_ch5r_bar_values(ax, bh(1), '%.1f', struct( ...
        'mode', 'inside', 'scale', 100, 'suffix', '%', ...
        'min_abs', 0.005, 'min_inside', 0.09, 'font_size', 9));
    annotate_ch5r_bar_values(ax, bh(2), '%.1f', struct( ...
        'mode', 'inside', 'scale', 100, 'suffix', '%', ...
        'min_abs', 0.005, 'min_inside', 0.09, 'font_size', 9));
    annotate_ch5r_bar_values(ax, bh(3), '%.1f', struct( ...
        'mode', 'inside', 'scale', 100, 'suffix', '%', ...
        'min_abs', 0.005, 'min_inside', 0.09, 'font_size', 9));
end

legend({'SC','DC','LoC'}, 'Location', 'eastoutside');
title(tl, 'Family-wise mean SC/DC/LoC occupancy');

png_file = fullfile(outdir, 'ch5r_multicase_family_state_occupancy_bar.png');
fig_file = fullfile(outdir, 'ch5r_multicase_family_state_occupancy_bar.fig');
saveas(fig, png_file);
savefig(fig, fig_file);
close(fig);

out = struct('png_file', png_file, 'fig_file', fig_file);
end
