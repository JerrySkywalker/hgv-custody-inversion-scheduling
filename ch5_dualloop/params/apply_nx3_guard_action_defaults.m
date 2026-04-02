function cfg = apply_nx3_guard_action_defaults(cfg)
%APPLY_NX3_GUARD_ACTION_DEFAULTS
% NX-3 second round defaults for guard action coupling.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    cfg.ch5 = struct();
end

if ~isfield(cfg.ch5, 'nx3_guard_action_mode') || isempty(cfg.ch5.nx3_guard_action_mode)
    cfg.ch5.nx3_guard_action_mode = 'none';
end
end
