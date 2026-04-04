function fig_path = plot_bubble_to_requirement_chain_real(outX, req_chain, out_dir, stamp)
%PLOT_BUBBLE_TO_REQUIREMENT_CHAIN_REAL
% Plot lambda_min and requirement-risk proxy on the same run.

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
plot(req_chain.t_s, req_chain.lambda_min, 'LineWidth', 1.2);
hold on
yline(req_chain.gamma_req, '--', 'LineWidth', 1.1);
ylabel('\lambda_{min}(J_W)');

yyaxis right
plot(req_chain.t_s, req_chain.req_risk_proxy, 'LineWidth', 1.2);
hold on
yline(req_chain.req_threshold_proxy, '--', 'LineWidth', 1.1);
ylabel('Requirement-risk proxy');

xlabel('Time (s)');
title('Bubble to Requirement-Risk Chain');
legend({'\lambda_{min}(J_W)','\gamma_{req}','req risk proxy','req threshold proxy'}, 'Location', 'best');
grid on

fig_path = fullfile(out_dir, ['plot_r6_chain_' stamp '.png']);
saveas(fig, fig_path);
close(fig);
end
