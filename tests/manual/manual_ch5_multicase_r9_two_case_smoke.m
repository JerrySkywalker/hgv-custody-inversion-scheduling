clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));
addpath(fullfile(pwd, 'ch5_rebuild', 'bootstrap'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));

case_ids = {'N01','H04_+30'};
methods = {'R9'};

out = run_ch5r_multicase_suite(struct( ...
    'case_set', 'smoke', ...
    'case_ids', {case_ids}, ...
    'methods', {methods}, ...
    'lock_name', 'ch5_constellation_lock', ...
    'save_case_mat', false, ...
    'fail_fast', true));

assert(out.ok);
T = out.table;

assert(height(T) == 2);
assert(all(T.method == "R9"));
assert(any(T.requested_case_id == "N01"));
assert(any(T.requested_case_id == "H04_+30"));
assert(any(T.actual_case_id == "N01"));
assert(any(T.actual_case_id == "H04_+30"));
assert(all(isfinite(T.mean_rmse_pos_km)));
assert(all(isfinite(T.final_rmse_pos_km)));

disp('=== manual_ch5_multicase_r9_two_case_smoke passed ===')
disp(T(:, {'method','requested_case_id','actual_case_id','family','bubble_steps','mean_rmse_pos_km','final_rmse_pos_km'}))
