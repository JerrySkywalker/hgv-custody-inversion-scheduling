function figs = plot_window_sweep_curves(scene_name, rows, out_dir)
%PLOT_WINDOW_SWEEP_CURVES  Plot Phase 9 sweep curves for one scene.
%
% rows: struct array with fields
%   method
%   T_w
%   q_worst_window
%   phi_mean
%   outage_ratio
%   longest_outage_steps
%   mean_rmse

if ~exist(out_dir, 'dir'); mkdir(out_dir); end

methods = unique(string({rows.method}), 'stable');

figs = struct();

figs.qworst = local_plot_metric(rows, methods, 'q_worst_window', scene_name, ...
    'q\_worst\_window', fullfile(out_dir, ['phase9_qworst_', scene_name, '.png']), true);

figs.phi = local_plot_metric(rows, methods, 'phi_mean', scene_name, ...
    '\phi mean', fullfile(out_dir, ['phase9_phi_mean_', scene_name, '.png']), true);

figs.outage = local_plot_metric(rows, methods, 'outage_ratio', scene_name, ...
    'Outage ratio', fullfile(out_dir, ['phase9_outage_', scene_name, '.png']), false);

figs.longest = local_plot_metric(rows, methods, 'longest_outage_steps', scene_name, ...
    'Longest outage steps', fullfile(out_dir, ['phase9_longest_', scene_name, '.png']), false);

figs.rmse = local_plot_metric(rows, methods, 'mean_rmse', scene_name, ...
    'Mean RMSE', fullfile(out_dir, ['phase9_rmse_', scene_name, '.png']), false);
end

function fig = local_plot_metric(rows, methods, field_name, scene_name, ylab, save_path, higher_is_better)
fig = figure('Color', 'w', 'Visible', 'off', 'Position', [100 100 900 600]);
hold on; grid on;

for i = 1:numel(methods)
    m = methods(i);
    mask = string({rows.method}) == m;
    sub = rows(mask);
    Tw = [sub.T_w];
    Y = [sub.(field_name)];
    [Tw, idx] = sort(Tw);
    Y = Y(idx);
    plot(Tw, Y, '-o', 'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', char(m));
end

xlabel('T_w (steps)', 'Interpreter', 'none');
ylabel(ylab, 'Interpreter', 'tex');

if higher_is_better
    title(['Phase 9 Window Sweep (higher better) - ', scene_name, ' - ', field_name], 'Interpreter', 'none');
else
    title(['Phase 9 Window Sweep (lower better) - ', scene_name, ' - ', field_name], 'Interpreter', 'none');
end

legend('Location', 'best');
exportgraphics(fig, save_path, 'Resolution', 220);
close(fig);
end
