function out = run_ch5r_phase0_bootstrap_smoke()
%RUN_CH5R_PHASE0_BOOTSTRAP_SMOKE  Formal smoke runner for Chapter 5 rebuild R0.

cfg = default_ch5r_params(false);
bundle = bootstrap_ch5r_from_stage04_stage05(cfg);

disp(' ')
disp('=== [ch5r:R0] bootstrap summary ===')
disp(['stage04 source : ' bundle.stage04.file])
disp(['stage05 source : ' bundle.stage05.file])
disp(['stage05 kind   : ' bundle.stage05.cache_kind])
disp(['gamma_req      : ' num2str(bundle.gamma_req, '%.12g')])
disp(['forced case    : ' bundle.target_case.case_id])
disp(['strict ok      : ' num2str(bundle.consistency.ok)])

disp(' ')
disp('theta_star = ')
disp(bundle.theta_star)

disp('theta_plus = ')
disp(bundle.theta_plus)

disp('target_case = ')
disp(bundle.target_case)

if isfield(bundle, 'consistency')
    disp('consistency = ')
    disp(bundle.consistency)
end

assert(isfield(bundle, 'theta_star'));
assert(isfield(bundle, 'theta_plus'));
assert(isfield(bundle, 'target_case'));
assert(isfield(bundle, 'gamma_req'));
assert(bundle.gamma_req > 0);

assert(bundle.consistency.ok, '[ch5r:R0] strict bootstrap validation failed.');
assert(strcmp(bundle.target_case.case_id, 'N01'), '[ch5r:R0] target_case.case_id must be N01.');
assert(strcmp(bundle.theta_star.case_id, 'N01'), '[ch5r:R0] theta_star.case_id must be N01.');
assert(strcmp(bundle.theta_plus.case_id, 'N01'), '[ch5r:R0] theta_plus.case_id must be N01.');
assert(~bundle.theta_star.used_fallback, '[ch5r:R0] theta_star fallback is forbidden.');
assert(~bundle.theta_plus.used_fallback, '[ch5r:R0] theta_plus fallback is forbidden.');
assert(bundle.theta_plus.Ns > bundle.theta_star.Ns, '[ch5r:R0] theta_plus.Ns must exceed theta_star.Ns.');

out = struct();
out.cfg = cfg;
out.bundle = bundle;
out.ok = true;

disp('[ch5r:R0] bootstrap smoke passed.')
end
