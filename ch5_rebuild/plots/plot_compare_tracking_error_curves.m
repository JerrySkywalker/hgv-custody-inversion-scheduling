function fig = plot_compare_tracking_error_curves(t_s, errA, errB, nameA, nameB, visible)
%PLOT_COMPARE_TRACKING_ERROR_CURVES Plot two tracking error curves.

if nargin < 6
    visible = 'off';
end

t_s = t_s(:);
errA = errA(:);
errB = errB(:);

fig = figure('Visible', visible);
plot(t_s, errA, 'LineWidth', 1.5);
hold on;
plot(t_s, errB, 'LineWidth', 1.5);
grid on;
xlabel('time (s)');
ylabel('position error norm');
title('tracking error comparison');
legend({char(nameA), char(nameB)}, 'Location', 'best');
end
