function fig = plot_tildeMR_vs_weight_timeline(k_idx, tildeMR, alpha_series, beta_series, eta_series, visible)
%PLOT_TILDEMR_VS_WEIGHT_TIMELINE Plot \tilde{M}_R and outerB weights over time.

if nargin < 6
    visible = 'off';
end

fig = figure('Visible', visible);

subplot(4,1,1);
plot(k_idx, tildeMR, 'LineWidth', 1.5);
grid on;
ylabel('\tilde{M}_R');
title('outerB weights driven by \tilde{M}_R');

subplot(4,1,2);
plot(k_idx, alpha_series, 'LineWidth', 1.5);
grid on;
ylabel('\alpha_k');

subplot(4,1,3);
plot(k_idx, beta_series, 'LineWidth', 1.5);
grid on;
ylabel('\beta_k');

subplot(4,1,4);
plot(k_idx, eta_series, 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('\eta_k');
end
