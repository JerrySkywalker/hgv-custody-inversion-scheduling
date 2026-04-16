clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));

out = run_ch5r_phase4c_full_pipeline(struct( ...
    'methods', {'R4','R9'}, ...
    'max_cases', 3, ...
    'suite_save_case_mat', false, ...
    'suite_fail_fast', true, ...
    'visible_mode', 'off'));

assert(out.ok);
assert(numel(out.case_ids) == 3);
assert(height(out.phase4ab.phase4a.stats.overall) >= 2);

disp('=== manual_ch5_phase4c_full_lite_smoke passed ===')
disp(out.case_ids)
disp(out.phase4ab.phase4a.stats.overall(:, {'method','n_cases','bubble_fraction_mean','mean_rmse_pos_km_mean'}))
disp(out.paths)
