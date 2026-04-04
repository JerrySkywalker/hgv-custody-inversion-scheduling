function policy = policy_tracking_greedy(cfg, ch5case)
%POLICY_TRACKING_GREEDY  Minimal tracking-oriented greedy baseline for R4.
%
% Current note:
% This is still a proxy policy under the synthetic information case.
% It creates a time-varying selection trace to differentiate from static_hold.

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

for k = 1:N
    lambda_diag = diag(ch5case.info_series(:,:,k));
    score = sum(lambda_diag(1:3));

    if score < ch5case.gamma_req * 1.8
        schedule{k} = theta_plus;
    else
        schedule{k} = theta_star;
    end
end

policy = struct();
policy.name = 'tracking_greedy';
policy.description = ['Minimal time-varying greedy baseline. Under weak instantaneous ' ...
    'information, it switches to theta_plus; otherwise it uses theta_star.'];
policy.theta_star = theta_star;
policy.theta_plus = theta_plus;
policy.schedule = schedule;
policy.meta = struct();
policy.meta.phase_name = 'R4';
policy.meta.source = mfilename;
policy.meta.case_id = ch5case.target_case.case_id;
end
