clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));

% 1) verify current smoke set
smoke = resolve_ch5r_case_list(struct('case_set','smoke'));
disp(smoke.case_ids)
assert(numel(smoke.case_ids) == 2);
assert(any(strcmp(smoke.case_ids, 'N01')));
assert(any(strcmp(smoke.case_ids, 'H04_+30')));

% 2) run multicase suite on 2-case smoke
outSuite = run_ch5r_multicase_suite(struct( ...
    'case_set', 'smoke', ...
    'methods', {{'R4','R5','R9','R10'}}, ...
    'save_case_mat', false, ...
    'fail_fast', true));

assert(outSuite.ok);
T = outSuite.table;

% 3) verify new state ratio columns exist
required_cols = {'SC_ratio','DC_ratio','LoC_ratio','bubble_time_s'};
for i = 1:numel(required_cols)
    assert(ismember(required_cols{i}, T.Properties.VariableNames), ...
        'Missing suite column: %s', required_cols{i});
end

% 4) run phase4A summary
outA = run_ch5r_phase4a_suite_summary(struct('suite_source', outSuite));
assert(outA.ok);

Tall = outA.stats.summary_all;
Tfam = outA.stats.summary_by_family;

% 5) verify quantile/std/UQ-mean columns
required_summary_cols = { ...
    'LoC_ratio_q1', 'LoC_ratio_std', 'LoC_ratio_upper_quartile_mean', ...
    'DC_ratio_q1',  'DC_ratio_std',  'DC_ratio_upper_quartile_mean', ...
    'SC_ratio_q1',  'SC_ratio_std',  'SC_ratio_upper_quartile_mean', ...
    'bubble_time_s_q1', 'bubble_time_s_std', 'bubble_time_s_upper_quartile_mean', ...
    'switch_count_q1', 'switch_count_std', 'switch_count_upper_quartile_mean'};

for i = 1:numel(required_summary_cols)
    assert(ismember(required_summary_cols{i}, Tall.Properties.VariableNames), ...
        'Missing overall summary column: %s', required_summary_cols{i});
end

disp('=== manual_ch5_phase4d_smoke passed ===')
disp(Tall(:, {'method','n_cases', ...
    'LoC_ratio_mean','DC_ratio_mean','SC_ratio_mean', ...
    'bubble_time_s_mean','switch_count_mean'}))
disp(Tfam(:, {'method','family','n_cases', ...
    'LoC_ratio_mean','bubble_time_s_mean'}))
disp(outA.paths)
