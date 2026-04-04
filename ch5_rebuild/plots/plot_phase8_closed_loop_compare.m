function fig = plot_phase8_closed_loop_compare(names, mean_rmse_truth, bubble_time_s, viol_time_s, switch_count, visible)
%PLOT_PHASE8_CLOSED_LOOP_COMPARE Compact compare chart for multiple methods.

if nargin < 6
    visible = 'off';
end

fig = figure('Visible', visible);

subplot(4,1,1);
bar(mean_rmse_truth);
grid on;
ylabel('mean RMSE');
set(gca, 'XTickLabel', names);
title('Phase R8 compare bundle');

subplot(4,1,2);
bar(bubble_time_s);
grid on;
ylabel('bubble time');
set(gca, 'XTickLabel', names);

subplot(4,1,3);
bar(viol_time_s);
grid on;
ylabel('req viol time');
set(gca, 'XTickLabel', names);

subplot(4,1,4);
bar(switch_count);
grid on;
ylabel('switch count');
set(gca, 'XTickLabel', names);
end
