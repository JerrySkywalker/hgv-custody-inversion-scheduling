function out = eval_requirement_margin(lambda_max_PR_series, Gamma_req, dt)
%EVAL_REQUIREMENT_MARGIN Evaluate requirement-bound margin metrics.
%
% margin(k) = Gamma_req - lambda_max(P_R(k))
%
% violation if margin < 0

x = lambda_max_PR_series(:);
N = numel(x);

assert(isnumeric(Gamma_req) && isscalar(Gamma_req), 'Gamma_req invalid.');
assert(isnumeric(dt) && isscalar(dt) && dt > 0, 'dt invalid.');

margin = Gamma_req - x;
is_violation = margin < 0;

out = struct();
out.margin = margin;
out.is_violation = is_violation;
out.min_margin = min(margin);
out.mean_margin = mean(margin);
out.total_violation_steps = sum(is_violation);
out.total_violation_time_s = sum(is_violation) * dt;
out.violation_fraction = mean(is_violation);
end
