function fig_file = plot_worst_window_bubble_depth_series(neighborhoods, output_dir, stamp)
%PLOT_WORST_WINDOW_BUBBLE_DEPTH_SERIES
assert(isstruct(neighborhoods), 'neighborhoods must be struct array.');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

fig = figure('Visible', 'off');
hold on
for i = 1:numel(neighborhoods)
    nb = neighborhoods(i);
    plot(nb.local_table.step_index, nb.local_table.bubble_depth, 'LineWidth', 1.5);
end
xlabel('Step index');
ylabel('Bubble depth');
title('Worst-window neighborhood: bubble depth');
grid on
legend({neighborhoods.tag}, 'Interpreter', 'none', 'Location', 'best');
hold off

fig_file = fullfile(output_dir, ['plot_R86b_worst_bubble_depth_' stamp '.png']);
saveas(fig, fig_file);
close(fig);
end
