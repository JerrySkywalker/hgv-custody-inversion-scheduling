function fig = plot_outerA_mode_timeline(k_idx, mode_code_series, visible)
%PLOT_OUTERA_MODE_TIMELINE Plot outerA mode code over time.

if nargin < 3
    visible = 'off';
end

fig = figure('Visible', visible);
stairs(k_idx, mode_code_series, 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('mode code');
title('outerA mode timeline');
ylim([0.5, 4.5]);
yticks([1 2 3 4]);
yticklabels({'safe','warn','repair','emergency'});
end
