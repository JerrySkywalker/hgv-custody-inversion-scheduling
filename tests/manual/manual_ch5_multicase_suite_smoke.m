clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));
addpath(fullfile(pwd, 'ch5_rebuild', 'bootstrap'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));

which load_ch5r_runtime_override
which activate_ch5r_runtime_override
which clear_ch5r_runtime_override
which apply_ch5r_lock_to_bundle
which extract_ch5r_suite_row
which run_ch5r_multicase_suite
which resolve_ch5r_case_list

smoke_case_ids = {'N01', 'H04_+30'};
smoke_methods = {'R4'};

% --------------------------------
% preflight: case list resolver
% --------------------------------
pre = resolve_ch5r_case_list(struct( ...
    'case_set', 'smoke', ...
    'case_ids', {smoke_case_ids}));

assert(numel(pre.case_ids) == 2);
assert(any(strcmp(pre.case_ids, 'N01')));
assert(any(strcmp(pre.case_ids, 'H04_+30')));

% --------------------------------
% multicase smoke only: two cases, one stable method (R4)
% --------------------------------
out = run_ch5r_multicase_suite(struct( ...
    'case_set', 'smoke', ...
    'case_ids', {smoke_case_ids}, ...
    'methods', {smoke_methods}, ...
    'lock_name', 'ch5_constellation_lock', ...
    'save_case_mat', false, ...
    'fail_fast', true));

assert(out.ok);
T = out.table;

assert(height(T) == 2);
assert(all(T.method == "R4"));
assert(any(T.requested_case_id == "N01"));
assert(any(T.requested_case_id == "H04_+30"));
assert(any(T.actual_case_id == "N01"));
assert(any(T.actual_case_id == "H04_+30"));

disp('=== Phase3A multicase suite smoke passed ===')
disp(out.paths)
disp(T(:, {'method','requested_case_id','actual_case_id','family','valid_steps','bubble_steps'}))
