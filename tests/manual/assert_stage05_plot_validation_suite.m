function assert_stage05_plot_validation_suite()
startup;

out = manual_smoke_stage05_plot_validation_suite();

assert(isequal(size(out.reproduction.grid_table), [210 26]), ...
    'Unexpected reproduction grid size.');

env_tbl = out.reproduction.outputs.best_pass_by_Ns;
hm = out.reproduction.outputs.geometry_heatmap_i60;

assert(height(env_tbl) == 17, ...
    'Unexpected best_pass_by_Ns height.');

assert(issorted(env_tbl.Ns), ...
    'best_pass_by_Ns.Ns is not sorted ascending.');

assert(all(env_tbl.pass_ratio >= 0 & env_tbl.pass_ratio <= 1), ...
    'best_pass_by_Ns.pass_ratio is outside [0,1].');

assert(isfile(char(out.plot_outputs.best_pass_plot.file_path)), ...
    'Best-pass plot file was not created.');

assert(isequal(size(hm.value_matrix), [5 6]), ...
    'Unexpected heatmap value_matrix size.');

assert(isequal(hm.row_values(:)', [4 6 8 10 12]), ...
    'Unexpected heatmap row_values.');

assert(isequal(hm.col_values(:)', [4 6 8 10 12 16]), ...
    'Unexpected heatmap col_values.');

assert(isfile(char(out.plot_outputs.heatmap_i60_plot.file_path)), ...
    'Heatmap plot file was not created.');

assert(isfile(char(out.plot_manifest.manifest_mat)), ...
    'Plot validation manifest MAT file was not created.');

assert(isfile(char(out.plot_manifest.manifest_txt)), ...
    'Plot validation manifest TXT file was not created.');

disp('assert_stage05_plot_validation_suite passed.');
end
