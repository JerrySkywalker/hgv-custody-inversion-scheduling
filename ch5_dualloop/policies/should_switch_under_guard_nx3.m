function [do_switch, info] = should_switch_under_guard_nx3(prev_sm, sm_now, G, k, cfg)
%SHOULD_SWITCH_UNDER_GUARD_NX3
% NX-3 first round
% Composite guard:
%   dwell gate
%   +
%   (state upgrade OR ttl threshold OR mg proxy threshold OR bad-window flag)

cfg = apply_nx2_state_machine_defaults(cfg);
cfg = apply_nx3_guard_defaults(cfg);

if nargin < 1 || isempty(prev_sm)
    prev_sm = struct();
    prev_sm.state_id = 0;
    prev_sm.last_switch_k = 1;
end

if ~isfield(prev_sm, 'last_switch_k') || isempty(prev_sm.last_switch_k)
    prev_sm.last_switch_k = 1;
end

dwell_steps = cfg.ch5.nx2_dwell_steps;
dwell_ok = (k - prev_sm.last_switch_k) >= dwell_steps;
state_changed = sm_now.state_id ~= prev_sm.state_id;

if ~cfg.ch5.nx2_state_machine_enable
    do_switch = true;
else
    if ~dwell_ok
        do_switch = false;
    else
        if ~cfg.ch5.nx3_guard_enable
            do_switch = state_changed;
        else
            conds = false(1,4);

            if cfg.ch5.nx3_guard_use_state_upgrade
                conds(1) = G.state_upgraded;
            end
            if cfg.ch5.nx3_guard_use_ttl
                conds(2) = G.ttl_steps <= cfg.ch5.nx3_guard_ttl_steps;
            end
            if cfg.ch5.nx3_guard_use_mg_proxy
                conds(3) = G.mg_proxy <= cfg.ch5.nx3_guard_mg_threshold;
            end
            if cfg.ch5.nx3_guard_use_bad_window
                conds(4) = G.bad_window_flag;
            end

            do_switch = any(conds) && state_changed;
        end
    end
end

info = struct();
info.dwell_ok = dwell_ok;
info.state_changed = state_changed;
info.state_upgraded = G.state_upgraded;
info.ttl_steps = G.ttl_steps;
info.mg_proxy = G.mg_proxy;
info.bad_window_flag = G.bad_window_flag;
end
