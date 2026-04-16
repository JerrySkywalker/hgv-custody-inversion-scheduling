clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));

suite_csv = '';

% Optional manual override:
% suite_csv = 'C:\src\hgv-custody-inversion-scheduling-mb-v2\outputs\ch5_rebuild\multicase_suite\...\multicase_suite_results.csv';

if isempty(suite_csv)
    root_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'multicase_suite');
    files = dir(fullfile(root_dir, '**', 'multicase_suite_results*.csv'));
    assert(~isempty(files), 'No multicase suite csv found under outputs/ch5_rebuild/multicase_suite.');

    [~, idx] = max([files.datenum]);
    suite_csv = fullfile(files(idx).folder, files(idx).name);
end

disp('=== manual_ch5_phase4ab_smoke using suite csv ===')
disp(suite_csv)

out = run_ch5r_phase4ab_suite_summary_and_plots(struct( ...
    'suite_source', suite_csv, ...
    'visible_mode', 'off'));

assert(out.ok);

Tsrc = out.phase4a.source_table;
methods_in_source = unique(string(Tsrc.method));
families_in_source = unique(string(Tsrc.family));

assert(height(out.phase4a.stats.overall) == numel(methods_in_source));
assert(height(out.phase4a.stats.by_family) >= numel(families_in_source));

% Stronger checks: R4/R5/R9/R10 should have finite RMSE means when present.
overall = out.phase4a.stats.overall;
method_names = string(overall.method);

for m = ["R4","R5","R9","R10"]
    idx = method_names == m;
    if any(idx)
        assert(isfinite(overall.mean_rmse_pos_km_mean(idx)), ...
            'mean_rmse_pos_km_mean is NaN for method %s', m);
        assert(isfinite(overall.final_rmse_pos_km_mean(idx)), ...
            'final_rmse_pos_km_mean is NaN for method %s', m);
    end
end

disp('=== manual_ch5_phase4ab_smoke passed ===')
disp(out.phase4a.stats.overall(:, {'method','n_cases','bubble_fraction_mean','bubble_fraction_q75','mean_rmse_pos_km_mean','final_rmse_pos_km_mean'}))
disp(out.phase4a.stats.by_family(:, {'method','family','n_cases','bubble_fraction_mean','mean_rmse_pos_km_mean','final_rmse_pos_km_mean'}))
disp(out.phase4b.paths)
