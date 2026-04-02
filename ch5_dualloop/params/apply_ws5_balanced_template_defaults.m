function cfg = apply_ws5_balanced_template_defaults(cfg)
%APPLY_WS5_BALANCED_TEMPLATE_DEFAULTS
% P-Back-1
% Introduce stable balanced defaults without changing baseline default behavior.
%
% Balanced preset:
%   template_filter_topk = 4
%   library_pair_cap     = 10
%
% This helper is intentionally explicit. Call it from runners / experiments
% when enabling template-guided reference selection and filtering.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    cfg.ch5 = struct();
end

cfg.ch5.template_filter_profile = 'balanced';
cfg.ch5.template_filter_topk = 4;
cfg.ch5.library_pair_cap = 10;

if ~isfield(cfg.ch5, 'prior_enable') || isempty(cfg.ch5.prior_enable)
    cfg.ch5.prior_enable = false;
end

if ~isfield(cfg.ch5, 'template_filter_enable') || isempty(cfg.ch5.template_filter_enable)
    cfg.ch5.template_filter_enable = false;
end
end
