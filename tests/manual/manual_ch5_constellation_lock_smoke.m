clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'bootstrap'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));

which export_ch5r_constellation_candidates
which write_ch5r_constellation_lock
which read_ch5r_constellation_lock
which run_ch5r_choose_constellation_lock

cand = export_ch5r_constellation_candidates();
assert(cand.ok);
assert(height(cand.star_candidates) >= 1);
assert(height(cand.plus_candidates) >= 1);
assert(all(cand.star_candidates.pass_ratio >= 1 - 1e-12));
assert(all(cand.plus_candidates.pass_ratio >= 1 - 1e-12));

out = run_ch5r_choose_constellation_lock(struct( ...
    'interactive', false, ...
    'top_k', 5, ...
    'star_rank', 1, ...
    'plus_rank', 1, ...
    'lock_name', 'ch5_constellation_lock'));

assert(out.ok);
assert(abs(out.theta_star.pass_ratio - 1) < 1e-12);
assert(abs(out.theta_plus.pass_ratio - 1) < 1e-12);

lock = read_ch5r_constellation_lock();
assert(lock.ok);
assert(strcmp(lock.lock.target_case.case_id, 'N01'));
assert(abs(lock.lock.theta_star.pass_ratio - 1) < 1e-12);
assert(abs(lock.lock.theta_plus.pass_ratio - 1) < 1e-12);

disp('=== Phase1 constellation lock smoke passed ===')
disp(lock.paths)
