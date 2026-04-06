function result = package_ch5r_result_real(ch5case, selection_trace, wininfo, bubble, resource_score)
%PACKAGE_CH5R_RESULT_REAL
% Unified real result package for R1.5/R2/R3-real/R4-real.
%
% Important:
% Core statistics follow valid_for_bubble semantics from centered_full_only windows.

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
result.ch5case = ch5case;
result.selection_trace = selection_trace;
result.wininfo = wininfo;
result.bubble = bubble;

result.state_trace = struct();
result.state_trace.time_s = wininfo.t_s(:);
result.state_trace.lambda_min = bubble.lambda_min(:);
result.state_trace.gamma_req = gamma_req;
result.state_trace.valid_for_bubble = bubble.valid_for_bubble(:);
result.state_trace.is_bubble = bubble.is_bubble(:);
result.state_trace.bubble_depth = bubble.bubble_depth(:);
result.state_trace.meta = struct();
result.state_trace.meta.case_id = ch5case.target_case.case_id;
result.state_trace.meta.family = ch5case.target_case.family;
result.state_trace.meta.window_mode = ch5case.window.mode;
result.state_trace.meta.window_length_steps = ch5case.window.length_steps;
result.state_trace.meta.window_length_s = ch5case.window.length_s;

result.bubble_metrics = bubble_metrics;
result.custody_metrics = custody_metrics;
result.rmse_proxy_metrics = rmse_proxy_metrics;
result.requirement = requirement;
result.cost_metrics = cost_metrics;

result.bubble_steps = bubble_metrics.bubble_steps;
result.bubble_time_s = bubble_metrics.bubble_time_s;
result.max_bubble_depth = bubble_metrics.max_bubble_depth;
result.switch_count = cost_metrics.switch_count;
result.resource_score = cost_metrics.resource_score;

result.meta = struct();
result.meta.case_id = ch5case.target_case.case_id;
result.meta.family = ch5case.target_case.family;
result.meta.line = 'real';
result.meta.source = mfilename;
end
