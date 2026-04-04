function out = classify_nis_consistency(s_k, meas_dim, alpha)
%CLASSIFY_NIS_CONSISTENCY Classify NIS against chi-square consistency interval.
%
% Inputs:
%   s_k      : scalar NIS
%   meas_dim : measurement dimension m
%   alpha    : significance level, e.g. 0.05
%
% Outputs:
%   out.lower_bound
%   out.upper_bound
%   out.is_low
%   out.is_ok
%   out.is_high
%   out.label

assert(isnumeric(s_k) && isscalar(s_k) && isfinite(s_k) && s_k >= 0, ...
    's_k must be a finite nonnegative scalar.');
assert(isnumeric(meas_dim) && isscalar(meas_dim) && meas_dim >= 1, ...
    'meas_dim must be a positive scalar.');
assert(isnumeric(alpha) && isscalar(alpha) && alpha > 0 && alpha < 1, ...
    'alpha must be in (0,1).');

lower_bound = chi2inv(alpha / 2, meas_dim);
upper_bound = chi2inv(1 - alpha / 2, meas_dim);

is_low = s_k < lower_bound;
is_high = s_k > upper_bound;
is_ok = ~(is_low || is_high);

if is_low
    label = 'low';
elseif is_high
    label = 'high';
else
    label = 'ok';
end

out = struct();
out.lower_bound = lower_bound;
out.upper_bound = upper_bound;
out.is_low = is_low;
out.is_ok = is_ok;
out.is_high = is_high;
out.label = label;
end
