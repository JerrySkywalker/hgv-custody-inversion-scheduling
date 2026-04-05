function fig = plot_requirement_margin_forecast(k_idx, Xi_B_series, visible)
%PLOT_REQUIREMENT_MARGIN_FORECAST Plot requirement-induced bubble margin Xi_B over time.

if nargin < 3
    visible = 'off';
end

k_idx = k_idx(:);
Xi_B_series = Xi_B_series(:);
assert(numel(k_idx) == numel(Xi_B_series), 'k_idx and Xi_B_series must have same length.');

fig = figure('Visible', visible);
plot(k_idx, Xi_B_series, 'LineWidth', 1.5);
hold on;
yline(0, '--');
grid on;
xlabel('step');
ylabel('\Xi_B^{req}');
title('requirement-induced bubble margin');
legend({'\Xi_B','0-threshold'}, 'Location', 'best');
end
