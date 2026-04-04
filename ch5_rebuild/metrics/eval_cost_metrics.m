function cost = eval_cost_metrics(policy, selection_trace)
%EVAL_COST_METRICS  Minimal cost metrics for Chapter 5 rebuild.

if nargin < 1 || isempty(policy)
    error('policy is required.');
end
if nargin < 2 || isempty(selection_trace)
    selection_trace = {};
end

n = numel(selection_trace);

cost = struct();
cost.switch_count = 0;
cost.resource_score = 0;
cost.total_steps = n;
cost.policy_name = policy.name;

if n == 0
    return;
end

ns_values = zeros(n,1);
for k = 1:n
    if isfield(selection_trace{k}, 'theta') && isfield(selection_trace{k}.theta, 'Ns')
        ns_values(k) = selection_trace{k}.theta.Ns;
    end
end

cost.resource_score = mean(ns_values);

% Align initial-switch definition with policy logging.
if isfield(policy, 'params') && isfield(policy.params, 'count_initial_switch') && policy.params.count_initial_switch
    if isfield(policy, 'theta_star')
        if ~isequal(selection_trace{1}.theta, policy.theta_star)
            cost.switch_count = cost.switch_count + 1;
        end
    end
end

for k = 2:n
    a = selection_trace{k-1}.theta;
    b = selection_trace{k}.theta;
    if ~isequal(a, b)
        cost.switch_count = cost.switch_count + 1;
    end
end
end
