function fig = plot_true_rmse_timeline(k_idx, rmse_truth, rmse_cov, visible)
%PLOT_TRUE_RMSE_TIMELINE Plot truth-RMSE and covariance-RMSE over time.

if nargin < 4
    visible = 'off';
end

fig = figure('Visible', visible);
plot(k_idx, rmse_truth, 'LineWidth', 1.5);
hold on;
plot(k_idx, rmse_cov, 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('RMSE');
title('RMSE timeline');
legend({'truth','covariance'}, 'Location', 'best');
end
