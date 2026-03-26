function assert_stage05_validation_suite()
startup;

out = manual_smoke_stage05_validation_suite();

assert(isequal(size(out.reproduction.grid_table), [210 26]), ...
    'Unexpected reproduction grid size.');

assert(height(out.compare.best_pass_compare) == 17, ...
    'Unexpected best_pass_compare height.');

assert(height(out.compare.heatmap_compare) == 30, ...
    'Unexpected heatmap_compare height.');

assert(isfile(char(out.manifest.manifest_mat)), ...
    'Validation manifest MAT file was not created.');

assert(isfile(char(out.manifest.manifest_txt)), ...
    'Validation manifest TXT file was not created.');

disp('assert_stage05_validation_suite passed.');
end
