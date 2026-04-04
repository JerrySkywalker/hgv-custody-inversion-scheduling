function fig = plot_outerB_pair_timeline(k_idx, pair_trace, visible)
%PLOT_OUTERB_PAIR_TIMELINE Plot selected pair timeline.
%
% pair_trace: [N x 2]

if nargin < 3
    visible = 'off';
end

fig = figure('Visible', visible);
subplot(2,1,1);
stairs(k_idx, pair_trace(:,1), 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('pair(1)');
title('outerB selected pair timeline');

subplot(2,1,2);
stairs(k_idx, pair_trace(:,2), 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('pair(2)');
end
