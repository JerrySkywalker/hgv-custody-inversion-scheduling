function test_mb_small_formal_feasible_map_bootstrap()
startup;

result = plot_mb_small_formal_feasible_map();

assert(isfield(result, 'grid_data'), 'Missing grid_data.');
assert(isfield(result, 'png_path'), 'Missing png_path.');
assert(isfield(result, 'fig_path'), 'Missing fig_path.');
assert(isfield(result, 'manifest_txt'), 'Missing manifest_txt.');

assert(isfile(result.png_path), 'Missing feasible map PNG.');
assert(isfile(result.fig_path), 'Missing feasible map FIG.');
assert(isfile(result.manifest_txt), 'Missing feasible map manifest TXT.');

disp('test_mb_small_formal_feasible_map_bootstrap passed.');
end
