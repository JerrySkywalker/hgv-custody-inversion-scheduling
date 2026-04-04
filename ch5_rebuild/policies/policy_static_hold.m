function policy = policy_static_hold(cfg, ch5case)
%POLICY_STATIC_HOLD  Static-hold baseline policy for Chapter 5 R3.
%
% Policy meaning:
%   keep the bootstrap static-feasible constellation unchanged
%   across the whole horizon.
%
% Current R3 note:
%   this policy does not yet change synthetic info_series generation.
%   its role is to formalize the first baseline strategy layer.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params();
end

if nargin < 2 || isempty(ch5case)
    ch5case = build_ch5r_case(cfg);
end

theta = cfg.ch5r.theta_star;
N = numel(ch5case.time_s);

policy = struct();
policy.name = 'static_hold';
policy.description = ['Hold the bootstrap static-feasible constellation ' ...
    'fixed over the full horizon without dynamic repair.'];
policy.theta = theta;
policy.schedule = repmat({theta}, N, 1);
policy.meta = struct();
policy.meta.phase_name = 'R3';
policy.meta.source = mfilename;
policy.meta.case_id = ch5case.target_case.case_id;
end
