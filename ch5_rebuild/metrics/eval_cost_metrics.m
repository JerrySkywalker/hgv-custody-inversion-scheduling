function out = eval_cost_metrics(switch_cost_series, pair_series)
%EVAL_COST_METRICS Evaluate switching/resource style cost metrics.

assert(isnumeric(switch_cost_series) && isvector(switch_cost_series), 'switch_cost_series invalid.');
assert(isnumeric(pair_series) && size(pair_series,2) == 2, 'pair_series invalid.');

switch_cost_series = switch_cost_series(:);

out = struct();
out.switch_count = sum(switch_cost_series > 0);
out.mean_switch_cost = mean(switch_cost_series);
out.first_pair = pair_series(1,:);
out.last_pair = pair_series(end,:);
end
