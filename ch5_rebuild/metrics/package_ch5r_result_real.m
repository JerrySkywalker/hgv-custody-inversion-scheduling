function result = package_ch5r_result_real(ch5case, selection_trace, wininfo, bubble, resource_score)
%PACKAGE_CH5R_RESULT_REAL
% Unified real result package for R3-real / R4-real.

if nargin < 5
    error('ch5case, selection_trace, wininfo, bubble, resource_score are required.');
end

dt = ch5case.dt;
gamma_req = ch5case.gamma_req;

bubble_metrics = eval_bubble_metrics_real(bubble, dt);
custody_metrics = eval_custody_metrics_real(bubble, dt);
rmse_proxy_metrics = eval_rmse_metrics_real(wininfo);
requirement = eval_requirement_margin_real(wininfo, gamma_req);
cost_metrics = eval_cost_metrics_real(selection_trace, resource_score);

result = struct();
result.bubble_metrics = bubble_metrics;
result.custody_metrics = custody_metrics;
result.rmse_proxy_metrics = rmse_proxy_metrics;
result.requirement = requirement;
result.cost_metrics = cost_metrics;

% Backward-compatible convenience fields for current runners / compare bundles
result.bubble_steps = bubble_metrics.bubble_steps;
result.bubble_time_s = bubble_metrics.bubble_time_s;
result.max_bubble_depth = bubble_metrics.max_bubble_depth;
result.switch_count = cost_metrics.switch_count;
result.resource_score = cost_metrics.resource_score;

result.meta = struct();
result.meta.case_id = ch5case.target_case.case_id;
result.meta.family = ch5case.target_case.family;
result.meta.line = 'real';
end
