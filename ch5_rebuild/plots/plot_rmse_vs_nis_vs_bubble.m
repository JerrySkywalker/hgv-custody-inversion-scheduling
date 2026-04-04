function fig = plot_rmse_vs_nis_vs_bubble(k_idx, rmse_truth, nis_series, is_bubble, visible)
%PLOT_RMSE_VS_NIS_VS_BUBBLE Plot RMSE, NIS, and bubble flag.

if nargin < 5
    visible = 'off';
end

fig = figure('Visible', visible);

subplot(3,1,1);
plot(k_idx, rmse_truth, 'LineWidth', 1.5);
grid on;
ylabel('RMSE_{truth}');
title('RMSE vs NIS vs bubble');

subplot(3,1,2);
plot(k_idx, nis_series, 'LineWidth', 1.5);
grid on;
ylabel('NIS');

subplot(3,1,3);
stairs(k_idx, double(is_bubble), 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('bubble');
ylim([-0.1 1.1]);
end
