function fig_path = plot_requirement_margin_vs_bubble_real(outX, req_chain, out_dir, stamp)
%PLOT_REQUIREMENT_MARGIN_VS_BUBBLE_REAL
% Plot requirement-margin proxy and bubble flag.

if nargin < 3 || isempty(out_dir)
    out_dir = pwd;
end
if nargin < 4 || isempty(stamp)
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

fig = figure('Visible', 'off');

yyaxis left
plot(req_chain.t_s, req_chain.req_margin_proxy, 'LineWidth', 1.2);
hold on
yline(0, '--', 'LineWidth', 1.1);
ylabel('Requirement margin proxy');

yyaxis right
stairs(outX.bubble.t_s, double(outX.bubble.is_bubble), 'LineWidth', 1.1);
ylabel('Bubble flag');
ylim([-0.1 1.1]);

xlabel('Time (s)');
title('Requirement Margin Proxy vs Bubble');
legend({'req margin proxy','zero line','bubble flag'}, 'Location', 'best');
grid on

fig_path = fullfile(out_dir, ['plot_r6_margin_vs_bubble_' stamp '.png']);
saveas(fig, fig_path);
close(fig);
end
