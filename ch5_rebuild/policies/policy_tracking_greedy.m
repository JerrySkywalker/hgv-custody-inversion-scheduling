function policy = policy_tracking_greedy(cfg, ch5case)
%POLICY_TRACKING_GREEDY  Minimal tracking-oriented greedy baseline for R4b.
%
% Rule:
%   if instantaneous information is weak, switch to theta_plus;
%   otherwise use theta_star.

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

tau_track = 0.72 * ch5case.gamma_req;

for k = 1:N
    if inst_lambda_min(k) < tau_track
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
policy.inst_lambda_min = inst_lambda_min;
policy.tau_track = tau_track;
policy.meta = struct();
policy.meta.phase_name = 'R4';
policy.meta.source = mfilename;
policy.meta.case_id = ch5case.target_case.case_id;
end
