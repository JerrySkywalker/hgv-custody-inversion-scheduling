function fig_path = stage13_plot_family_overview(signature_table, family_name, paths)
%STAGE13_PLOT_FAMILY_OVERVIEW Plot family-level worst-margin overview.

style = milestone_common_plot_style();
rows = signature_table(strcmp(string(signature_table.family), string(family_name)), :);
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120 90 980 420]);
ax = axes(fig);
hold(ax, 'on');

x = 1:height(rows);
plot(ax, x, rows.D_G_worst, 'o-', 'LineWidth', 1.5, 'Color', style.colors(1, :), 'DisplayName', 'D_G^{worst}');
plot(ax, x, rows.D_A_worst, 's-', 'LineWidth', 1.5, 'Color', style.colors(2, :), 'DisplayName', 'D_A^{worst}');
plot(ax, x, rows.D_T_worst, 'd-', 'LineWidth', 1.5, 'Color', style.colors(3, :), 'DisplayName', 'D_T^{worst}');
yline(ax, 1, ':', 'Color', style.threshold_color, 'LineWidth', 1.2, 'DisplayName', 'threshold');

active_idx = find(strcmp(string(rows.active_constraint), "DG") | strcmp(string(rows.active_constraint), "joint"));
scatter(ax, x(active_idx), rows.D_G_worst(active_idx), 54, style.colors(1, :), 'filled', 'HandleVisibility', 'off');
active_idx = find(strcmp(string(rows.active_constraint), "DA") | strcmp(string(rows.active_constraint), "joint"));
scatter(ax, x(active_idx), rows.D_A_worst(active_idx), 54, style.colors(2, :), 'filled', 'HandleVisibility', 'off');
active_idx = find(strcmp(string(rows.active_constraint), "DT") | strcmp(string(rows.active_constraint), "joint"));
scatter(ax, x(active_idx), rows.D_T_worst(active_idx), 54, style.colors(3, :), 'filled', 'HandleVisibility', 'off');

xticks(ax, x);
xticklabels(ax, cellstr(rows.case_tag));
xtickangle(ax, 25);
xlabel(ax, 'candidate index', 'Interpreter', 'tex');
ylabel(ax, 'worst margin', 'Interpreter', 'tex');
title(ax, sprintf('Stage13 family overview: %s', family_name), 'Interpreter', 'tex');
legend(ax, 'Location', 'best', 'Interpreter', 'tex');
grid(ax, 'on');
apply_dissertation_plot_style(fig, style);

fig_path = fullfile(paths.figures, sprintf('stage13_family_overview_%s.png', family_name));
milestone_common_save_figure(fig, fig_path);
close(fig);
fig_path = string(fig_path);
end
