clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));

which run_ch5r_phase0_freeze_single_case_baseline
assert(~isempty(which('run_ch5r_phase0_freeze_single_case_baseline')))

out = run_ch5r_phase0_freeze_single_case_baseline();

assert(out.ok);

assert(strcmp(out.bootstrap.target_case, 'N01'));
assert(isstruct(out.bootstrap.theta_star));
assert(isstruct(out.bootstrap.theta_plus));
assert(abs(out.bootstrap.theta_star.pass_ratio - 1) < 1e-12);
assert(abs(out.bootstrap.theta_plus.pass_ratio - 1) < 1e-12);

for i = 1:numel(out.methods)
    s = out.methods(i);
    assert(strcmp(s.case_id, 'N01'));
    assert(strcmp(s.window_mode, 'centered_full_only'));
    assert(s.valid_steps > 0);
    assert(s.switch_count >= 0);
    assert(s.resource_score == 2 || isnan(s.resource_score));
end

assert(isfile(out.paths.mat_file));
assert(isfile(out.paths.json_file));
assert(isfile(out.paths.md_file));

disp('=== Phase0 single-case baseline freeze passed ===')
disp(out.paths)
