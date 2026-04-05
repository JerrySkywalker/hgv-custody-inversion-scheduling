function fig = plot_bubble_margin_XiB(k_idx, Xi_B_series, visible)
%PLOT_BUBBLE_MARGIN_XIB Plot bubble margin Xi_B over time.

if nargin < 3
    visible = 'off';
end

fig = figure('Visible', visible);
plot(k_idx, Xi_B_series, 'LineWidth', 1.5);
hold on;
yline(0, '--');
grid on;
xlabel('step');
ylabel('\Xi_B');
title('bubble margin \Xi_B timeline');
legend({'\Xi_B','0-threshold'}, 'Location', 'best');
end
