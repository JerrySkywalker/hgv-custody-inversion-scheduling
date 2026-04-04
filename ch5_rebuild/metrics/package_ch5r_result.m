function result = package_ch5r_result(out1)
%PACKAGE_CH5R_RESULT  Package minimal R2 result from Phase R1 output.

if nargin < 1 || isempty(out1)
    error('Phase R1 output is required.');
end

state_trace = out1.state_trace;
bubble_metrics = eval_bubble_metrics(state_trace);
requirement = eval_requirement_margin(state_trace);

result = struct();
result.state_trace = state_trace;
result.bubble_metrics = bubble_metrics;
result.requirement = requirement;

result.meta = struct();
result.meta.phase_name = 'R2';
result.meta.source = mfilename;
result.meta.case_id = state_trace.meta.case_id;
result.meta.family = state_trace.meta.family;
end
