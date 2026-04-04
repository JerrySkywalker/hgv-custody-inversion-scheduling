function out = run_ch5r_phase0_bootstrap_smoke()
%RUN_CH5R_PHASE0_BOOTSTRAP_SMOKE  Formal smoke runner for Chapter 5 rebuild R0.

cfg = default_ch5r_params();
bundle = bootstrap_ch5r_from_stage04_stage05(cfg);

disp(' ')
disp('=== [ch5r:R0] bootstrap summary ===')
disp(['stage04 source : ' bundle.stage04.file])
disp(['stage05 source : ' bundle.stage05.file])
disp(['stage05 kind   : ' bundle.stage05.cache_kind])
disp(['gamma_req      : ' num2str(bundle.gamma_req, '%.12g')])

disp(' ')
disp('theta_star = ')
disp(bundle.theta_star)

disp('theta_plus = ')
disp(bundle.theta_plus)

disp('target_case = ')
disp(bundle.target_case)

assert(isfield(bundle, 'theta_star'));
assert(isfield(bundle, 'theta_plus'));
assert(isfield(bundle, 'target_case'));
assert(isfield(bundle, 'gamma_req'));
assert(bundle.gamma_req > 0);

out = struct();
out.cfg = cfg;
out.bundle = bundle;
out.ok = true;

disp('[ch5r:R0] bootstrap smoke passed.')
end
