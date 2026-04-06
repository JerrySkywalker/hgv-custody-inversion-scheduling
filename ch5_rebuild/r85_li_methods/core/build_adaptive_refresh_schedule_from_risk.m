function out = build_adaptive_refresh_schedule_from_risk(lambda_series, gamma_req, opts)
%BUILD_ADAPTIVE_REFRESH_SCHEDULE_FROM_RISK
% R8.7b.2:
%   Build adaptive refresh schedule with stepwise monitoring and early refresh.
%
% Logic:
%   - At each refresh point, choose a nominal interval from risk level.
%   - During hold, monitor each subsequent step.
%   - If near-threshold / emergency-risk is reached, trigger early refresh immediately.

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
if ~isfield(opts, 'tau_emg'); opts.tau_emg = 0.02; end
if ~isfield(opts, 'eps_risk'); opts.eps_risk = 1e-6; end
if ~isfield(opts, 'guard_margin'); opts.guard_margin = 3000; end

lambda_series = lambda_series(:);
n_steps = numel(lambda_series);

risk_series = max(gamma_req - lambda_series, 0) ./ (gamma_req + opts.eps_risk);
near_threshold_mask = lambda_series < (gamma_req + opts.guard_margin);
emergency_mask = near_threshold_mask | (risk_series > opts.tau_emg);

interval_schedule = zeros(n_steps,1);
refresh_mask = false(n_steps,1);
refresh_mask(1) = true;

k_anchor = 1;
while k_anchor <= n_steps
    rk = risk_series(k_anchor);

    if near_threshold_mask(k_anchor)
        Tin_nominal = opts.T_short;
    elseif rk > opts.tau2
        Tin_nominal = opts.T_short;
    elseif rk > opts.tau1
        Tin_nominal = opts.T_mid;
    else
        Tin_nominal = opts.T_long;
    end

    interval_schedule(k_anchor) = Tin_nominal;

    k_end_nominal = min(n_steps, k_anchor + Tin_nominal - 1);
    k_next_refresh = [];

    % stepwise monitoring inside the hold interval
    for kk = k_anchor + 1 : k_end_nominal
        interval_schedule(kk) = Tin_nominal;

        if emergency_mask(kk)
            k_next_refresh = kk;
            refresh_mask(kk) = true;
            break;
        end
    end

    if isempty(k_next_refresh)
        k_next_refresh = k_anchor + Tin_nominal;
        if k_next_refresh <= n_steps
            refresh_mask(k_next_refresh) = true;
        end
    end

    k_anchor = k_next_refresh;
end

out = struct();
out.refresh_mask = refresh_mask;
out.interval_schedule = interval_schedule;
out.risk_series = risk_series;
out.near_threshold_mask = near_threshold_mask;
out.emergency_mask = emergency_mask;
out.opts = opts;
end
