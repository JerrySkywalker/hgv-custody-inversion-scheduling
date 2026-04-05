function fig = plot_AB_timeline(k_idx, A_B_series, visible)
%PLOT_AB_TIMELINE Plot violation area A_B over time.

if nargin < 3
    visible = 'off';
end

k_idx = k_idx(:);
A_B_series = A_B_series(:);
assert(numel(k_idx) == numel(A_B_series), 'k_idx and A_B_series must have same length.');

fig = figure('Visible', visible);
plot(k_idx, A_B_series, 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('A_B');
title('predicted requirement-violation area A_B');
end
