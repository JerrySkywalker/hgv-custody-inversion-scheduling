function fig = plot_compare_nis_timeline(t_s, nisA, nisB, lower, upper, nameA, nameB, visible)
%PLOT_COMPARE_NIS_TIMELINE Plot NIS time series for two policies with confidence bounds.

if nargin < 8
    visible = 'off';
end

t_s = t_s(:);
nisA = nisA(:);
nisB = nisB(:);

fig = figure('Visible', visible);
plot(t_s, nisA, 'LineWidth', 1.2);
hold on;
plot(t_s, nisB, 'LineWidth', 1.2);
yline(lower, '--');
yline(upper, '--');
grid on;
xlabel('time (s)');
ylabel('NIS');
title('NIS timeline comparison');
legend({char(nameA), char(nameB), 'lower bound', 'upper bound'}, 'Location', 'best');
end
