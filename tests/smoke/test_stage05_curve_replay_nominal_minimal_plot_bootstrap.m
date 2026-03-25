function test_stage05_curve_replay_nominal_minimal_plot_bootstrap()
startup;

result = plot_stage05_curve_replay_nominal_minimal();

assert(isfield(result, 'png_path'), 'Missing png_path.');
assert(isfield(result, 'fig_path'), 'Missing fig_path.');
assert(isfield(result, 'manifest_txt'), 'Missing manifest_txt.');

assert(isfile(result.png_path), 'Missing replay curve PNG.');
assert(isfile(result.fig_path), 'Missing replay curve FIG.');
assert(isfile(result.manifest_txt), 'Missing replay curve manifest TXT.');

disp('test_stage05_curve_replay_nominal_minimal_plot_bootstrap passed.');
end
