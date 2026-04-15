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
methods = {'R4'};

out = run_ch5r_multicase_suite(struct( ...
    'case_set', 'smoke', ...
    'case_ids', {case_ids}, ...
    'methods', {methods}, ...
    'lock_name', 'ch5_constellation_lock', ...
    'save_case_mat', false, ...
    'fail_fast', true));

assert(out.ok);
assert(height(out.table) == 2);
assert(any(out.table.requested_case_id == "N01"));
assert(any(out.table.requested_case_id == "H04_+30"));
assert(any(out.table.actual_case_id == "N01"));
assert(any(out.table.actual_case_id == "H04_+30"));

disp('=== manual_ch5_multicase_r4_two_case_smoke passed ===')
disp(out.table(:, {'method','requested_case_id','actual_case_id','family','bubble_steps','bubble_fraction'}))
