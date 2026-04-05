function fig_file = plot_worst_window_pair_trace(neighborhoods, output_dir, stamp)
%PLOT_WORST_WINDOW_PAIR_TRACE
assert(isstruct(neighborhoods), 'neighborhoods must be struct array.');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

fig = figure('Visible', 'off');
hold on
for i = 1:numel(neighborhoods)
    nb = neighborhoods(i);
    y = nb.local_table.pair_sat_1 + 0.01 * nb.local_table.pair_sat_2;
    plot(nb.local_table.step_index, y, 'LineWidth', 1.5);
end
xlabel('Step index');
ylabel('Pair trace proxy (sat1 + 0.01 sat2)');
title('Worst-window neighborhood: pair trace');
grid on
legend({neighborhoods.tag}, 'Interpreter', 'none', 'Location', 'best');
hold off

fig_file = fullfile(output_dir, ['plot_R86b_worst_pair_trace_' stamp '.png']);
saveas(fig, fig_file);
close(fig);
end
