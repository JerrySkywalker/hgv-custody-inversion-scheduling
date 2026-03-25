function test_framework_heatmap_slice_vs_legacy_stage05_grid()
startup;

repo_root = fileparts(fileparts(mfilename('fullpath')));
repo_root = fileparts(repo_root);
stage05_cache_dir = fullfile(repo_root, 'legacy', 'outputs', 'stage', 'stage05', 'cache');
d5 = dir(fullfile(stage05_cache_dir, 'stage05_nominal_walker_search*.mat'));
assert(~isempty(d5), 'No Stage05 nominal cache found.');
[~, idx] = max([d5.datenum]);
S = load(fullfile(d5(idx).folder, d5(idx).name));
legacy_grid = S.out.grid;

slice_tbl = slice_truth_table(legacy_grid, struct( ...
    'fixed_filters', struct('h_km', 1000, 'i_deg', 60), ...
    'keep_columns', {{'P','T','Ns','pass_ratio','feasible_flag','D_G_min'}}));

direct_tbl = legacy_grid(legacy_grid.h_km == 1000 & legacy_grid.i_deg == 60, ...
    {'P','T','Ns','pass_ratio','feasible_flag','D_G_min'});

assert(height(slice_tbl) == height(direct_tbl), 'Legacy heatmap slice row count mismatch.');
assert(isequal(sortrows(slice_tbl, {'P','T'}), sortrows(direct_tbl, {'P','T'})), ...
    'Legacy heatmap slice content mismatch.');

disp('test_framework_heatmap_slice_vs_legacy_stage05_grid passed.');
end
