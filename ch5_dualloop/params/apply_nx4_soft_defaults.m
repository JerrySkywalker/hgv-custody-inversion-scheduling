function cfg = apply_nx4_soft_defaults(cfg)
%APPLY_NX4_SOFT_DEFAULTS
% NX-4 second round defaults for soft proposal coupling.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    cfg.ch5 = struct();
end

if ~isfield(cfg.ch5, 'nx4_soft_enable') || isempty(cfg.ch5.nx4_soft_enable)
    cfg.ch5.nx4_soft_enable = true;
end

if ~isfield(cfg.ch5, 'nx4_soft_topk') || isempty(cfg.ch5.nx4_soft_topk)
    cfg.ch5.nx4_soft_topk = 4;
end

if ~isfield(cfg.ch5, 'nx4_soft_bonus_weight') || isempty(cfg.ch5.nx4_soft_bonus_weight)
    cfg.ch5.nx4_soft_bonus_weight = 0.05;
end

if ~isfield(cfg.ch5, 'nx4_soft_score_margin') || isempty(cfg.ch5.nx4_soft_score_margin)
    cfg.ch5.nx4_soft_score_margin = 0.10;
end
end
