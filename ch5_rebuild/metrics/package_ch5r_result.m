function result = package_ch5r_result(out1, policy, selection_trace)
%PACKAGE_CH5R_RESULT  Package minimal result bundle for Chapter 5 rebuild.

if nargin < 1 || isempty(out1)
    error('Phase output is required.');
end
if nargin < 2
    policy = struct();
end
if nargin < 3
    selection_trace = {};
end

state_trace = out1.state_trace;
bubble_metrics = eval_bubble_metrics(state_trace);
custody_metrics = eval_custody_metrics(state_trace);
rmse_metrics = eval_rmse_metrics(state_trace);
requirement = eval_requirement_margin(state_trace);

result = struct();
result.state_trace = state_trace;
result.bubble_metrics = bubble_metrics;
result.custody_metrics = custody_metrics;
result.rmse_metrics = rmse_metrics;
result.requirement = requirement;

if ~isempty(fieldnames(policy))
    result.cost_metrics = eval_cost_metrics(policy, selection_trace);
else
    result.cost_metrics = struct();
end

result.meta = struct();
result.meta.phase_name = 'R2plus';
result.meta.source = mfilename;
result.meta.case_id = state_trace.meta.case_id;
result.meta.family = state_trace.meta.family;
end
