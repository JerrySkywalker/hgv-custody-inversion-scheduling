function out = manual_smoke_stage05_plot_validation_suite()
startup;

artifact_root = fullfile('outputs','experiments','chapter4','stage05_plot_validation_suite','smoke');

out = run_stage05_plot_validation_suite( ...
    'artifact_root', artifact_root, ...
    'plot_visible', 'off', ...
    'show_progress', false);

disp('[manual] Stage05 plot validation suite smoke completed.');
disp(size(out.reproduction.grid_table));
disp(out.plot_outputs.best_pass_plot.file_path);
disp(out.plot_outputs.heatmap_i60_plot.file_path);
disp(out.plot_manifest.manifest_mat);
disp(out.plot_manifest.manifest_txt);
end
