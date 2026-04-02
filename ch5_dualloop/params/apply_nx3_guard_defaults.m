function cfg = apply_nx3_guard_defaults(cfg)
%APPLY_NX3_GUARD_DEFAULTS
% NX-3 first round defaults for composite guard logic.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    cfg.ch5 = struct();
end

if ~isfield(cfg.ch5, 'nx3_guard_enable') || isempty(cfg.ch5.nx3_guard_enable)
    cfg.ch5.nx3_guard_enable = true;
end

if ~isfield(cfg.ch5, 'nx3_guard_use_ttl') || isempty(cfg.ch5.nx3_guard_use_ttl)
    cfg.ch5.nx3_guard_use_ttl = true;
end

if ~isfield(cfg.ch5, 'nx3_guard_use_state_upgrade') || isempty(cfg.ch5.nx3_guard_use_state_upgrade)
    cfg.ch5.nx3_guard_use_state_upgrade = true;
end

if ~isfield(cfg.ch5, 'nx3_guard_use_mg_proxy') || isempty(cfg.ch5.nx3_guard_use_mg_proxy)
    cfg.ch5.nx3_guard_use_mg_proxy = true;
end

if ~isfield(cfg.ch5, 'nx3_guard_use_bad_window') || isempty(cfg.ch5.nx3_guard_use_bad_window)
    cfg.ch5.nx3_guard_use_bad_window = true;
end

if ~isfield(cfg.ch5, 'nx3_guard_ttl_steps') || isempty(cfg.ch5.nx3_guard_ttl_steps)
    cfg.ch5.nx3_guard_ttl_steps = 8;
end

if ~isfield(cfg.ch5, 'nx3_guard_mg_threshold') || isempty(cfg.ch5.nx3_guard_mg_threshold)
    cfg.ch5.nx3_guard_mg_threshold = 0.35;
end
end
