function cfg = default_phase8_continuous_prior_config()
% 默认连续先验配置

cfg = struct();

cfg.w_prior = 0.15;

cfg.weights = struct();
cfg.weights.wf = 1.0;
cfg.weights.wb = 0.5;
cfg.weights.wr = 1.5;

cfg.mode_list = {'ck_only', 'ck_plus_fragility', 'ck_plus_full_prior'};
cfg.default_mode = 'ck_plus_full_prior';

end
