function fig_files = plot_ch5_phase9_window_sweep(rows, scene_preset, fig_dir)
%PLOT_CH5_PHASE9_WINDOW_SWEEP
% Plot main Phase 9 sweep figures.

methods = unique(string({rows.method}));
tw_vals = unique([rows.Tw]);

fig_files = {};

% q_worst_window
f1 = figure('Visible', 'off');
hold on
for i = 1:numel(methods)
    m = methods(i);
    sub = rows(strcmp(string({rows.method}), m));
    [~, ord] = sort([sub.Tw]);
    sub = sub(ord);
    plot([sub.Tw], [sub.q_worst_window], 'LineWidth', 1.2);
end
xlabel('T_w', 'Interpreter', 'none');
ylabel('q_worst_window', 'Interpreter', 'none');
title(['Phase 9 q_worst_window - ', scene_preset], 'Interpreter', 'none');
legend(cellstr(methods), 'Interpreter', 'none', 'Location', 'best');
grid on
save_path1 = fullfile(fig_dir, ['phase9_q_worst_window_', scene_preset, '.png']);
saveas(f1, save_path1);
close(f1);
fig_files{end+1} = save_path1; %#ok<AGROW>

% outage_ratio
f2 = figure('Visible', 'off');
hold on
for i = 1:numel(methods)
    m = methods(i);
    sub = rows(strcmp(string({rows.method}), m));
    [~, ord] = sort([sub.Tw]);
    sub = sub(ord);
    plot([sub.Tw], [sub.outage_ratio], 'LineWidth', 1.2);
end
xlabel('T_w', 'Interpreter', 'none');
ylabel('outage_ratio', 'Interpreter', 'none');
title(['Phase 9 outage_ratio - ', scene_preset], 'Interpreter', 'none');
legend(cellstr(methods), 'Interpreter', 'none', 'Location', 'best');
grid on
save_path2 = fullfile(fig_dir, ['phase9_outage_ratio_', scene_preset, '.png']);
saveas(f2, save_path2);
close(f2);
fig_files{end+1} = save_path2; %#ok<AGROW>

% mean_rmse
f3 = figure('Visible', 'off');
hold on
for i = 1:numel(methods)
    m = methods(i);
    sub = rows(strcmp(string({rows.method}), m));
    [~, ord] = sort([sub.Tw]);
    sub = sub(ord);
    plot([sub.Tw], [sub.mean_rmse], 'LineWidth', 1.2);
end
xlabel('T_w', 'Interpreter', 'none');
ylabel('mean_rmse', 'Interpreter', 'none');
title(['Phase 9 mean_rmse - ', scene_preset], 'Interpreter', 'none');
legend(cellstr(methods), 'Interpreter', 'none', 'Location', 'best');
grid on
save_path3 = fullfile(fig_dir, ['phase9_mean_rmse_', scene_preset, '.png']);
saveas(f3, save_path3);
close(f3);
fig_files{end+1} = save_path3; %#ok<AGROW>
end
