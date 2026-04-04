function fig = plot_MR_vs_tildeMR(k_idx, MR_series, tildeMR_series, visible)
%PLOT_MR_VS_TILDEMR Plot M_R and \tilde{M}_R versus step index.

if nargin < 4
    visible = 'off';
end

fig = figure('Visible', visible);
plot(k_idx, MR_series, 'LineWidth', 1.5);
hold on;
plot(k_idx, tildeMR_series, 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('value');
title('M_R vs \tilde{M}_R');
legend({'M_R','\tilde{M}_R'}, 'Location', 'best');
end
