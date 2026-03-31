function tracking = eval_tracking_metrics(result)
%EVAL_TRACKING_METRICS  Evaluate minimal tracking metrics for chapter 5 shell.

assert(isfield(result, 'time'), 'Result must contain field: time');
assert(isfield(result, 'tracking_sat_count'), 'Result must contain field: tracking_sat_count');
assert(isfield(result, 'rmse_pos'), 'Result must contain field: rmse_pos');

t = result.time(:);
sat_count = result.tracking_sat_count(:);
rmse_pos = result.rmse_pos(:);

tracking = struct();
tracking.time = t;
tracking.tracking_sat_count = sat_count;
tracking.rmse_pos = rmse_pos;

tracking.coverage_ratio_ge1 = mean(sat_count >= 1);
tracking.coverage_ratio_ge2 = mean(sat_count >= 2);
tracking.mean_rmse = mean(rmse_pos);
tracking.max_rmse = max(rmse_pos);
end
