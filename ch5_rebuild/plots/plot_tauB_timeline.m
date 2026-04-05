function fig = plot_tauB_timeline(k_idx, tau_B_time_s, visible)
%PLOT_TAUB_TIMELINE Plot predicted first-failure time over time.
%
% Infinite values (no failure in window) are shown as NaN for plotting.

if nargin < 3
    visible = 'off';
end

k_idx = k_idx(:);
tau_B_time_s = tau_B_time_s(:);
assert(numel(k_idx) == numel(tau_B_time_s), 'k_idx and tau_B_time_s must have same length.');

tau_plot = tau_B_time_s;
tau_plot(~isfinite(tau_plot)) = NaN;

fig = figure('Visible', visible);
plot(k_idx, tau_plot, 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('\tau_B (s)');
title('predicted first-failure time \tau_B');
end
