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
methods = {'R4','R5','R9','R10'};

out = run_ch5r_multicase_suite(struct( ...
    'case_set', 'smoke', ...
    'case_ids', {case_ids}, ...
    'methods', {methods}, ...
    'lock_name', 'ch5_constellation_lock', ...
    'save_case_mat', false, ...
    'fail_fast', true));

assert(out.ok);
T = out.table;

assert(height(T) == 8);
assert(sum(T.method == "R4") == 2);
assert(sum(T.method == "R5") == 2);
assert(sum(T.method == "R9") == 2);
assert(sum(T.method == "R10") == 2);

assert(all(ismember(["N01","H04_+30"], unique(T.requested_case_id))));
assert(all(ismember(["N01","H04_+30"], unique(T.actual_case_id))));
assert(all(T.ok));

disp('=== manual_ch5_multicase_r4_r5_r9_r10_smoke passed ===')
disp(T(:, {'method','requested_case_id','actual_case_id','family','bubble_steps','bubble_fraction','switch_count','mean_rmse_pos_km'}))
