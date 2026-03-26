function profile = make_profile_stage05_nominal_plot_strict()
gamma_info = load_stage04_nominal_gamma_req();

profile = struct();
profile.name = 'stage05_nominal_plot_strict';
profile.mode = 'static';
profile.task_family = 'nominal';
profile.evaluator_mode = 'opend';

profile.runtime = struct();
profile.runtime.max_cases = inf;
profile.runtime.max_designs = inf;

profile.gamma_eff_scalar = gamma_info.gamma_req;
profile.gamma_source = gamma_info.gamma_source;
profile.gamma_cache_file = gamma_info.cache_file;
profile.Tw_s = gamma_info.Tw_s;
end
