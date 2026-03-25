function report = run_framework_vs_legacy_manual_regression()
startup;

report = struct();
report.stage01 = manual_compare_stage01_casebank();
report.stage02 = manual_compare_stage02_nominal_traj();
report.stage03_resource = manual_compare_stage03_resource();
report.stage03_visibility = manual_compare_stage03_visibility();
report.stage04_window = manual_compare_stage04_window();
report.stage06_heading_family = manual_compare_stage06_heading_family();

report.stage05_opend_smallset = manual_compare_stage05_opend_smallset();
report.stage09_closedd_smallset = manual_compare_stage09_closedd_smallset();

report.stage05_best_envelope = manual_compare_stage05_best_envelope();
report.stage05_heatmap_slice = manual_compare_stage05_heatmap_slice();

report.stage05_opend_fullgrid_i60 = manual_compare_stage05_opend_fullgrid_i60();
report.stage05_best_envelope_fullgrid_i60 = manual_compare_stage05_best_envelope_fullgrid_i60();
report.stage05_heatmap_fullgrid_i60 = manual_compare_stage05_heatmap_fullgrid_i60();

report.stage05_opend_fullgrid_all_i = manual_compare_stage05_opend_fullgrid_all_i();
report.stage05_best_envelope_fullgrid_all_i = manual_compare_stage05_best_envelope_fullgrid_all_i();
report.stage05_heatmap_fullgrid_all_i = manual_compare_stage05_heatmap_fullgrid_all_i();

disp('=== Framework vs Legacy Manual Regression ===');
disp(report);
end
