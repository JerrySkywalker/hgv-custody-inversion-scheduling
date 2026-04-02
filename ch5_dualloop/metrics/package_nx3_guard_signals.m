function G = package_nx3_guard_signals(outerA, sm_prev, sm_now, ttl_steps_now, k, cfg)
%PACKAGE_NX3_GUARD_SIGNALS
% NX-3 first round
% Minimal online guard signal packer.

cfg = apply_nx3_guard_defaults(cfg);

G = struct();
G.k = k;
G.ttl_steps = ttl_steps_now;
G.risk_state_now = outerA.risk_state(k);
G.state_prev = sm_prev.state_id;
G.state_now = sm_now.state_id;
G.state_upgraded = sm_now.state_id > sm_prev.state_id;
G.mode_now = string(sm_now.mode);

% First-round M_G proxy:
% use a bounded monotone transform from risk_state:
%   risk 0 -> 1.0
%   risk 1 -> 0.5
%   risk 2 -> 0.0
G.mg_proxy = max(0, 1 - 0.5 * double(G.risk_state_now));

% First-round bad-window proxy:
G.bad_window_flag = (double(G.risk_state_now) >= 1);
end
