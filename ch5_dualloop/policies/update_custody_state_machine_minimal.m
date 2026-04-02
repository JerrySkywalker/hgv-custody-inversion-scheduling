function sm = update_custody_state_machine_minimal(prev_sm, risk_state_now, k, cfg)
%UPDATE_CUSTODY_STATE_MACHINE_MINIMAL
% NX-2 first round
% Minimal three-state custody machine with hysteresis.
%
% state_id:
%   0 = safe
%   1 = warn
%   2 = trigger

cfg = apply_nx2_state_machine_defaults(cfg);

if nargin < 1 || isempty(prev_sm)
    prev_sm = struct();
    prev_sm.state_id = 0;
    prev_sm.state_name = "safe";
    prev_sm.last_switch_k = 1;
    prev_sm.mode = "safe";
end

state_prev = prev_sm.state_id;
state_new = state_prev;

warn_enter = cfg.ch5.nx2_warn_enter;
warn_exit = cfg.ch5.nx2_warn_exit;
trigger_enter = cfg.ch5.nx2_trigger_enter;
trigger_exit = cfg.ch5.nx2_trigger_exit;

r = risk_state_now;

switch state_prev
    case 0  % safe
        if r >= trigger_enter
            state_new = 2;
        elseif r >= warn_enter
            state_new = 1;
        else
            state_new = 0;
        end

    case 1  % warn
        if r >= trigger_enter
            state_new = 2;
        elseif r <= warn_exit
            state_new = 0;
        else
            state_new = 1;
        end

    otherwise % trigger
        if r <= warn_exit
            state_new = 0;
        elseif r <= trigger_exit
            state_new = 1;
        else
            state_new = 2;
        end
end

sm = prev_sm;
sm.k = k;
sm.risk_state_now = r;
sm.state_id = state_new;

switch state_new
    case 0
        sm.state_name = "safe";
        sm.mode = "safe";
    case 1
        sm.state_name = "warn";
        sm.mode = "warn";
    otherwise
        sm.state_name = "trigger";
        sm.mode = "trigger";
end

if state_new ~= state_prev
    sm.last_switch_k = k;
end
end
