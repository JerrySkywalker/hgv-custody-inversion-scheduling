function out = manual_smoke_stage05_validation_suite()
startup;

artifact_root = fullfile('outputs','experiments','chapter4','stage05_validation_suite','smoke');

out = run_stage05_validation_suite( ...
    'artifact_root', artifact_root, ...
    'show_progress', false);

disp('[manual] Stage05 validation suite smoke completed.');
disp(size(out.reproduction.grid_table));
disp(height(out.compare.best_pass_compare));
disp(height(out.compare.heatmap_compare));
disp(out.manifest.manifest_mat);
disp(out.manifest.manifest_txt);
end
