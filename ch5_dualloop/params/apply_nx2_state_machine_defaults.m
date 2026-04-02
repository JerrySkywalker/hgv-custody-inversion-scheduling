function cfg = apply_nx2_state_machine_defaults(cfg)
%APPLY_NX2_STATE_MACHINE_DEFAULTS
% NX-2 first round
% Minimal state-machine defaults:
%   - dwell
%   - hysteresis
%   - guard
%
% This helper only fills missing fields and does not override
% user-specified values.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    cfg.ch5 = struct();
end

if ~isfield(cfg.ch5, 'nx2_state_machine_enable') || isempty(cfg.ch5.nx2_state_machine_enable)
    cfg.ch5.nx2_state_machine_enable = true;
end

if ~isfield(cfg.ch5, 'nx2_dwell_steps') || isempty(cfg.ch5.nx2_dwell_steps)
    cfg.ch5.nx2_dwell_steps = 8;
end

if ~isfield(cfg.ch5, 'nx2_warn_enter') || isempty(cfg.ch5.nx2_warn_enter)
    cfg.ch5.nx2_warn_enter = 1;
end

if ~isfield(cfg.ch5, 'nx2_warn_exit') || isempty(cfg.ch5.nx2_warn_exit)
    cfg.ch5.nx2_warn_exit = 0;
end

if ~isfield(cfg.ch5, 'nx2_trigger_enter') || isempty(cfg.ch5.nx2_trigger_enter)
    cfg.ch5.nx2_trigger_enter = 2;
end

if ~isfield(cfg.ch5, 'nx2_trigger_exit') || isempty(cfg.ch5.nx2_trigger_exit)
    cfg.ch5.nx2_trigger_exit = 1;
end

if ~isfield(cfg.ch5, 'nx2_guard_enable') || isempty(cfg.ch5.nx2_guard_enable)
    cfg.ch5.nx2_guard_enable = true;
end

if ~isfield(cfg.ch5, 'nx2_guard_ttl_steps') || isempty(cfg.ch5.nx2_guard_ttl_steps)
    cfg.ch5.nx2_guard_ttl_steps = 16;
end

if ~isfield(cfg.ch5, 'nx2_guard_require_state_change') || isempty(cfg.ch5.nx2_guard_require_state_change)
    cfg.ch5.nx2_guard_require_state_change = true;
end

if ~isfield(cfg.ch5, 'nx2_mode_when_disabled') || isempty(cfg.ch5.nx2_mode_when_disabled)
    cfg.ch5.nx2_mode_when_disabled = 'warn';
end
end
