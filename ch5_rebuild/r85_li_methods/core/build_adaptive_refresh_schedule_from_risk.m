function out = build_adaptive_refresh_schedule_from_risk(lambda_series, gamma_req, opts)
%BUILD_ADAPTIVE_REFRESH_SCHEDULE_FROM_RISK
% R8.7b:
%   Build adaptive refresh schedule from risk / near-threshold condition.
%
% Output:
%   refresh_mask(k) = true means refresh at step k
%   interval_schedule(k) = interval selected at step k

assert(isnumeric(lambda_series) && isvector(lambda_series), 'lambda_series must be numeric vector.');
assert(isnumeric(gamma_req) && isscalar(gamma_req), 'gamma_req invalid.');

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'T_long'); opts.T_long = 60; end
if ~isfield(opts, 'T_mid'); opts.T_mid = 20; end
if ~isfield(opts, 'T_short'); opts.T_short = 10; end
if ~isfield(opts, 'tau1'); opts.tau1 = 0.02; end
if ~isfield(opts, 'tau2'); opts.tau2 = 0.10; end
if ~isfield(opts, 'eps_risk'); opts.eps_risk = 1e-6; end
if ~isfield(opts, 'guard_margin'); opts.guard_margin = 3000; end

lambda_series = lambda_series(:);
n_steps = numel(lambda_series);

risk_series = max(gamma_req - lambda_series, 0) ./ (gamma_req + opts.eps_risk);
near_threshold_mask = lambda_series < (gamma_req + opts.guard_margin);

interval_schedule = zeros(n_steps,1);
refresh_mask = false(n_steps,1);
refresh_mask(1) = true;

k = 1;
while k <= n_steps
    rk = risk_series(k);

    if near_threshold_mask(k)
        Tin = opts.T_short;
    elseif rk > opts.tau2
        Tin = opts.T_short;
    elseif rk > opts.tau1
        Tin = opts.T_mid;
    else
        Tin = opts.T_long;
    end

    interval_schedule(k) = Tin;

    k_next = k + Tin;
    if k_next <= n_steps
        refresh_mask(k_next) = true;
    end

    for kk = k+1:min(n_steps, k+Tin-1)
        interval_schedule(kk) = Tin;
    end

    k = k_next;
end

out = struct();
out.refresh_mask = refresh_mask;
out.interval_schedule = interval_schedule;
out.risk_series = risk_series;
out.near_threshold_mask = near_threshold_mask;
out.opts = opts;
end
