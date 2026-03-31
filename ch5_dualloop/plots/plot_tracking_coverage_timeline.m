function fig = plot_tracking_coverage_timeline(result, out_png)
%PLOT_TRACKING_COVERAGE_TIMELINE  Plot selected tracking satellite count over time.

t = result.time(:);
count = result.tracking_sat_count(:);

fig = figure('Visible', 'off');
plot(t, count, 'LineWidth', 1.2);
xlabel('Time (s)')
ylabel('Tracking Satellite Count')
title('Chapter 5 Phase 3 Tracking Coverage Timeline')
grid on

if nargin >= 2 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
