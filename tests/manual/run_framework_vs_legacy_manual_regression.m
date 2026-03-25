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

disp('=== Framework vs Legacy Manual Regression ===');
disp(report);
end
