function policy = policy_tracking_greedy(cfg, ch5case)
%POLICY_TRACKING_GREEDY  Minimal tracking-oriented greedy baseline for R4b.3.
%
% Hysteresis rule with minimum hold duration:
%   if inst info < tau_low, switch to theta_plus
%   if inst info > tau_high, switch to theta_star
%   otherwise hold previous selection
%   after switching, respect minimum hold steps

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params();
end
if nargin < 2 || isempty(ch5case)
    ch5case = build_ch5r_case(cfg);
end

theta_star = cfg.ch5r.theta_star;
theta_plus = cfg.ch5r.theta_plus;
N = numel(ch5case.time_s);

r4 = cfg.ch5r.r4;
tau_low  = r4.tau_low_ratio  * ch5case.gamma_req;
tau_high = r4.tau_high_ratio * ch5case.gamma_req;

schedule = cell(N, 1);

inst_lambda_min = zeros(N, 1);
for k = 1:N
    inst_lambda_min(k) = min(eig(ch5case.info_series(:,:,k)));
end

current_theta = theta_star;
hold_counter = 0;
for k = 1:N
    s = inst_lambda_min(k);

    if hold_counter > 0
        hold_counter = hold_counter - 1;
    else
        if isequal(current_theta, theta_star)
            if s < tau_low
                current_theta = theta_plus;
                hold_counter = max(r4.min_hold_steps_plus - 1, 0);
            end
        else
            if s > tau_high
                current_theta = theta_star;
                hold_counter = max(r4.min_hold_steps_star - 1, 0);
            end
        end
    end

    schedule{k} = current_theta;
end

policy = struct();
policy.name = 'tracking_greedy';
policy.description = ['Tracking-oriented greedy baseline with hysteresis and minimum hold steps.'];
policy.theta_star = theta_star;
policy.theta_plus = theta_plus;
policy.schedule = schedule;
policy.inst_lambda_min = inst_lambda_min;
policy.tau_low = tau_low;
policy.tau_high = tau_high;
policy.params = r4;
policy.meta = struct();
policy.meta.phase_name = 'R4';
policy.meta.source = mfilename;
policy.meta.case_id = ch5case.target_case.case_id;
end
