clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));
addpath(fullfile(pwd, 'ch5_rebuild', 'bootstrap'));

cfg = default_ch5r_params();
disp('=== ch5r gamma_req ===')
disp(cfg.ch5r.gamma_req)

disp('=== ch5r theta_star ===')
disp(cfg.ch5r.theta_star)

disp('=== ch5r theta_plus ===')
disp(cfg.ch5r.theta_plus)

disp('=== ch5r target_case ===')
disp(cfg.ch5r.target_case)

bundle = bootstrap_ch5r_from_stage04_stage05(cfg);
disp('=== bootstrap output files ===')
disp(bundle.paths)

assert(isfield(bundle, 'theta_star'));
assert(isfield(bundle, 'theta_plus'));
assert(isfield(bundle, 'target_case'));
assert(isfield(bundle, 'gamma_req'));
assert(bundle.gamma_req > 0);

disp('R0 bootstrap smoke passed.')
