function fig = plot_phase2p5_candidates_summary(candidates, out_png)
%PLOT_PHASE2P5_CANDIDATES_SUMMARY  Plot candidate count timeline.

t = candidates.vis_case.t_s(:);
count = candidates.count(:);

fig = figure('Visible', 'off');
plot(t, count, 'LineWidth', 1.2);
xlabel('Time (s)')
ylabel('Candidate Count')
title('Chapter 5 Phase 2.5B Candidate Count Summary')
grid on

if nargin >= 2 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
