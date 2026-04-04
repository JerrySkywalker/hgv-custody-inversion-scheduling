function policy = policy_tracking_greedy(cfg, ch5case)
%POLICY_TRACKING_GREEDY  Minimal tracking-oriented greedy baseline for R4b.1.
%
% Hysteresis rule:
%   if instantaneous information is below tau_low, switch to theta_plus
%   if instantaneous information is above tau_high, switch to theta_star
%   otherwise hold previous selection

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params();
end
if nargin < 2 || isempty(ch5case)
    ch5case = build_ch5r_case(cfg);
end

theta_star = cfg.ch5r.theta_star;
theta_plus = cfg.ch5r.theta_plus;
N = numel(ch5case.time_s);

schedule = cell(N, 1);

inst_lambda_min = zeros(N, 1);
for k = 1:N
    inst_lambda_min(k) = min(eig(ch5case.info_series(:,:,k)));
end

tau_low  = 0.68 * ch5case.gamma_req;
tau_high = 0.92 * ch5case.gamma_req;

current_theta = theta_star;
for k = 1:N
    s = inst_lambda_min(k);

    if s < tau_low
        current_theta = theta_plus;
    elseif s > tau_high
        current_theta = theta_star;
    end

    schedule{k} = current_theta;
end

policy = struct();
policy.name = 'tracking_greedy';
policy.description = ['Minimal time-varying greedy baseline with hysteresis. ' ...
    'Below tau_low use theta_plus; above tau_high use theta_star; ' ...
    'otherwise hold previous selection.'];
policy.theta_star = theta_star;
policy.theta_plus = theta_plus;
policy.schedule = schedule;
policy.inst_lambda_min = inst_lambda_min;
policy.tau_low = tau_low;
policy.tau_high = tau_high;
policy.meta = struct();
policy.meta.phase_name = 'R4';
policy.meta.source = mfilename;
policy.meta.case_id = ch5case.target_case.case_id;
end
