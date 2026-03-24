function files = stage13_plot_case_vs_baseline(baseline_eval, candidate_eval, family_name, paths, output_tag)
%STAGE13_PLOT_CASE_VS_BASELINE Plot Stage13 baseline-vs-candidate comparisons.

if nargin < 5 || strlength(string(output_tag)) == 0
    output_tag = candidate_eval.signature.case_tag;
end

style = milestone_common_plot_style();
base_curve = baseline_eval.scan_out.window_table;
cand_curve = candidate_eval.scan_out.window_table;
case_tag = char(candidate_eval.signature.case_tag);
file_tag = char(string(output_tag));

curve_fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120 80 980 860]);
tl = tiledlayout(curve_fig, 3, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
metrics = { ...
    'DG_window', 'D_G', 1.0; ...
    'DA_window', 'D_A', 1.0; ...
    'DT_bar_window', 'D_{T,bar}', 0.5};
for i = 1:size(metrics, 1)
    ax = nexttile(tl);
    hold(ax, 'on');
    plot(ax, base_curve.t0_s, base_curve.(metrics{i, 1}), '-', 'LineWidth', 1.8, 'Color', style.colors(1, :), 'DisplayName', 'baseline');
    plot(ax, cand_curve.t0_s, cand_curve.(metrics{i, 1}), '--', 'LineWidth', 1.8, 'Color', style.colors(2, :), 'DisplayName', 'candidate');
    yline(ax, metrics{i, 3}, ':', 'Color', style.threshold_color, 'LineWidth', 1.2, 'DisplayName', 'threshold');
    ylabel(ax, metrics{i, 2}, 'Interpreter', 'tex');
    grid(ax, 'on');
    if i == 1
        title(ax, sprintf('Stage13 %s: baseline vs %s', family_name, case_tag), 'Interpreter', 'tex');
        legend(ax, 'Location', 'best', 'Interpreter', 'tex');
    end
    if i == size(metrics, 1)
        xlabel(ax, '窗口起点 t_0 (s)', 'Interpreter', 'tex');
    end
end
apply_dissertation_plot_style(curve_fig, style);

curve_path = fullfile(paths.figures, sprintf('stage13_case_%s_vs_baseline.png', file_tag));
milestone_common_save_figure(curve_fig, curve_path);
close(curve_fig);

worst_fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120 80 900 380]);
ax = axes(worst_fig);
hold(ax, 'on');
ypos = [1 2 3];
labels = {'DG', 'DA', 'DT'};
baseline_t0 = [baseline_eval.signature.t0G_star, baseline_eval.signature.t0A_star, baseline_eval.signature.t0T_star];
candidate_t0 = [candidate_eval.signature.t0G_star, candidate_eval.signature.t0A_star, candidate_eval.signature.t0T_star];
plot(ax, baseline_t0, ypos, 'o-', 'LineWidth', 1.6, 'Color', style.colors(1, :), 'MarkerSize', 7, 'DisplayName', 'baseline');
plot(ax, candidate_t0, ypos, 's--', 'LineWidth', 1.6, 'Color', style.colors(2, :), 'MarkerSize', 7, 'DisplayName', 'candidate');
yticks(ax, ypos);
yticklabels(ax, labels);
xlabel(ax, '最坏窗口起点 t_0^* (s)', 'Interpreter', 'tex');
ylabel(ax, '指标', 'Interpreter', 'tex');
title(ax, sprintf('Stage13 %s: worst-window comparison', family_name), 'Interpreter', 'tex');
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Interpreter', 'tex');
apply_dissertation_plot_style(worst_fig, style);

worst_path = fullfile(paths.figures, sprintf('stage13_case_%s_worst_windows.png', file_tag));
milestone_common_save_figure(worst_fig, worst_path);
close(worst_fig);

files = struct('curve_compare', string(curve_path), 'worst_window_compare', string(worst_path));
end
