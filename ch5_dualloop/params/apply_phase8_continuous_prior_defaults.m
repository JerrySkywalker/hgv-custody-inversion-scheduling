function cfg = apply_phase8_continuous_prior_defaults(cfg)
%APPLY_PHASE8_CONTINUOUS_PRIOR_DEFAULTS
% Attach default config for Phase08 continuous prior integration.

if ~isfield(cfg, 'ch5')
    cfg.ch5 = struct();
end

if ~isfield(cfg.ch5, 'continuous_prior_enable')
    cfg.ch5.continuous_prior_enable = false;
end
if ~isfield(cfg.ch5, 'continuous_prior_mode')
    cfg.ch5.continuous_prior_mode = 'ck_plus_full_prior';
end
if ~isfield(cfg.ch5, 'continuous_prior_w_prior')
    cfg.ch5.continuous_prior_w_prior = 0.15;
end
if ~isfield(cfg.ch5, 'continuous_prior_wf')
    cfg.ch5.continuous_prior_wf = 1.0;
end
if ~isfield(cfg.ch5, 'continuous_prior_wb')
    cfg.ch5.continuous_prior_wb = 0.5;
end
if ~isfield(cfg.ch5, 'continuous_prior_wr')
    cfg.ch5.continuous_prior_wr = 1.5;
end
end
