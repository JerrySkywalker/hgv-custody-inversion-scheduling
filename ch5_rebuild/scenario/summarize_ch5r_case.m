function summary = summarize_ch5r_case(ch5case)
%SUMMARIZE_CH5R_CASE  Minimal case summary for Chapter 5 rebuild.

if nargin < 1 || isempty(ch5case)
    error('ch5case is required.');
end

summary = struct();
summary.case_id = ch5case.target_case.case_id;
summary.family = ch5case.target_case.family;
summary.theta = ch5case.theta;
summary.gamma_req = ch5case.gamma_req;
summary.time_span_s = [ch5case.time_s(1), ch5case.time_s(end)];
summary.window_length_s = ch5case.window.length_s;
summary.total_steps = numel(ch5case.time_s);
end
