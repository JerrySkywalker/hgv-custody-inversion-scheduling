function [do_switch, info] = should_switch_under_guard_minimal(prev_sm, sm_now, ttl_steps_now, k, cfg)
%SHOULD_SWITCH_UNDER_GUARD_MINIMAL
% NX-2 first round
% Minimal dwell + guard decision.
%
% Switch is allowed only if:
%   - dwell is satisfied
%   - and state transition is meaningful under guard logic

cfg = apply_nx2_state_machine_defaults(cfg);

if nargin < 1 || isempty(prev_sm)
    prev_sm = struct();
    prev_sm.state_id = 0;
    prev_sm.last_switch_k = 1;
end

if nargin < 3 || isempty(ttl_steps_now) || ~isfinite(ttl_steps_now)
    ttl_steps_now = inf;
end

if ~isfield(prev_sm, 'last_switch_k') || isempty(prev_sm.last_switch_k)
    prev_sm.last_switch_k = 1;
end

dwell_steps = cfg.ch5.nx2_dwell_steps;
guard_enable = cfg.ch5.nx2_guard_enable;
guard_ttl_steps = cfg.ch5.nx2_guard_ttl_steps;
require_state_change = cfg.ch5.nx2_guard_require_state_change;

state_changed = sm_now.state_id ~= prev_sm.state_id;
state_upgraded = sm_now.state_id > prev_sm.state_id;
dwell_ok = (k - prev_sm.last_switch_k) >= dwell_steps;

if ~cfg.ch5.nx2_state_machine_enable
    do_switch = true;
else
    if ~dwell_ok
        do_switch = false;
    else
        if ~guard_enable
            if require_state_change
                do_switch = state_changed;
            else
                do_switch = true;
            end
        else
            do_switch = false;
            if state_upgraded
                do_switch = true;
            end
            if ttl_steps_now <= guard_ttl_steps
                do_switch = true;
            end
            if require_state_change && ~state_changed
                do_switch = false;
            end
        end
    end
end

info = struct();
info.state_changed = state_changed;
info.state_upgraded = state_upgraded;
info.dwell_ok = dwell_ok;
info.ttl_steps_now = ttl_steps_now;
info.guard_enable = guard_enable;
info.guard_ttl_steps = guard_ttl_steps;
end
