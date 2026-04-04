function cost_metrics = eval_cost_metrics_real(selection_trace, resource_score)
%EVAL_COST_METRICS_REAL
% Cost metrics on the real R3/R4 line.

if nargin < 1 || isempty(selection_trace)
    error('selection_trace is required.');
end
if nargin < 2 || isempty(resource_score)
    error('resource_score is required.');
end

N = numel(selection_trace);
switch_count = 0;

for k = 2:N
    a = selection_trace{k-1}.pair;
    b = selection_trace{k}.pair;

    if ~isempty(a) && ~isempty(b) && ~isequal(a, b)
        switch_count = switch_count + 1;
    end
end

cost_metrics = struct();
cost_metrics.switch_count = switch_count;
cost_metrics.resource_score = resource_score;
cost_metrics.total_steps = N;
end
