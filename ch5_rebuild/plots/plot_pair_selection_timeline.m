function fig = plot_pair_selection_timeline(k_idx, pair_series, visible)
%PLOT_PAIR_SELECTION_TIMELINE Plot selected pair indices over time.

if nargin < 3
    visible = 'off';
end

assert(isnumeric(pair_series) && size(pair_series,2) == 2, 'pair_series must be [N x 2].');

fig = figure('Visible', visible);
plot(k_idx, pair_series(:,1), 'LineWidth', 1.5);
hold on;
plot(k_idx, pair_series(:,2), 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('satellite index');
title('selected pair timeline');
legend({'pair(:,1)','pair(:,2)'}, 'Location', 'best');
end
