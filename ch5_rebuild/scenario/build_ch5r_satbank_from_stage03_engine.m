function satbank = build_ch5r_satbank_from_stage03_engine(cfg, truth)
%BUILD_CH5R_SATBANK_FROM_STAGE03_ENGINE
% Build a real fixed constellation satbank using theta_star on the truth time grid.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(false);
end
if nargin < 2 || isempty(truth)
    truth = build_ch5r_truth_from_stage02_engine(cfg);
end

cfg_local = cfg;

% Use theta_star as the single fixed constellation for the whole R4 experiment.
cfg_local.stage03.h_km = cfg.ch5r.theta_star.h_km;
cfg_local.stage03.i_deg = cfg.ch5r.theta_star.i_deg;
cfg_local.stage03.P    = cfg.ch5r.theta_star.P;
cfg_local.stage03.T    = cfg.ch5r.theta_star.T;
cfg_local.stage03.F    = cfg.ch5r.theta_star.F;

walker = build_single_layer_walker_stage03(cfg_local);
satbank = propagate_constellation_stage03(walker, truth.t_s);

satbank.source = 'stage03_real_builder_from_theta_star';
satbank.meta = struct();
satbank.meta.theta_star = cfg.ch5r.theta_star;
satbank.meta.note = 'Single real fixed constellation built on truth time grid.';
end
