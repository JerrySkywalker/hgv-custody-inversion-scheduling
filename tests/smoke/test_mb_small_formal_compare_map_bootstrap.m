function test_mb_small_formal_compare_map_bootstrap()
startup;

result = plot_mb_small_formal_compare_map();

assert(isfield(result, 'grid_data'), 'Missing grid_data.');
assert(isfield(result, 'png_path'), 'Missing png_path.');
assert(isfield(result, 'fig_path'), 'Missing fig_path.');
assert(isfield(result, 'manifest_txt'), 'Missing manifest_txt.');

assert(isfile(result.png_path), 'Missing compare map PNG.');
assert(isfile(result.fig_path), 'Missing compare map FIG.');
assert(isfile(result.manifest_txt), 'Missing compare map manifest TXT.');

disp('test_mb_small_formal_compare_map_bootstrap passed.');
end
