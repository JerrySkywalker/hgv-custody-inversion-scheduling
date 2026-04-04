function cfg = build_ch5r_params_from_bootstrap(cfg, bundle)
%BUILD_CH5R_PARAMS_FROM_BOOTSTRAP  Merge bootstrap bundle into cfg.ch5r.

if nargin < 2 || isempty(bundle)
    error('Bootstrap bundle is required.');
end

cfg.ch5r.bootstrap_result = bundle;
cfg.ch5r.bootstrap_result.available = true;

cfg.ch5r.stage04 = bundle.stage04;
cfg.ch5r.stage05 = bundle.stage05;

cfg.ch5r.theta_star = bundle.theta_star;
cfg.ch5r.theta_plus = bundle.theta_plus;
cfg.ch5r.target_case = bundle.target_case;
cfg.ch5r.sensor_profile = bundle.sensor_profile;
cfg.ch5r.gamma_req = bundle.gamma_req;

cfg.ch5r.case = struct();
cfg.ch5r.case.case_id = bundle.target_case.case_id;
cfg.ch5r.case.family = bundle.target_case.family;

cfg.ch5r.constellation = struct();

cfg.ch5r.constellation.theta_star = struct();
cfg.ch5r.constellation.theta_star.h_km = bundle.theta_star.h_km;
cfg.ch5r.constellation.theta_star.i_deg = bundle.theta_star.i_deg;
cfg.ch5r.constellation.theta_star.P = bundle.theta_star.P;
cfg.ch5r.constellation.theta_star.T = bundle.theta_star.T;
cfg.ch5r.constellation.theta_star.F = bundle.theta_star.F;
cfg.ch5r.constellation.theta_star.Ns = bundle.theta_star.Ns;

cfg.ch5r.constellation.theta_plus = struct();
cfg.ch5r.constellation.theta_plus.h_km = bundle.theta_plus.h_km;
cfg.ch5r.constellation.theta_plus.i_deg = bundle.theta_plus.i_deg;
cfg.ch5r.constellation.theta_plus.P = bundle.theta_plus.P;
cfg.ch5r.constellation.theta_plus.T = bundle.theta_plus.T;
cfg.ch5r.constellation.theta_plus.F = bundle.theta_plus.F;
cfg.ch5r.constellation.theta_plus.Ns = bundle.theta_plus.Ns;
end
