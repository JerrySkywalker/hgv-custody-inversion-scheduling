function assert_framework_vs_legacy_manual_regression()
startup;

report = run_framework_vs_legacy_manual_regression();

assert(report.stage01.nominal_count_match == 1, 'Stage01 nominal count mismatch.');
assert(report.stage01.first_case_match == 1, 'Stage01 first case mismatch.');

assert(report.stage02.time_count_match == 1, 'Stage02 time count mismatch.');
assert(report.stage02.state_size_match == 1, 'Stage02 state size mismatch.');

assert(report.stage03_resource.Ns_match == 1, 'Stage03 resource Ns mismatch.');
assert(report.stage03_resource.r_size_match == 1, 'Stage03 resource state size mismatch.');
assert(report.stage03_resource.time_count_match == 1, 'Stage03 resource time count mismatch.');

assert(report.stage03_visibility.num_visible_size_match == 1, 'Stage03 visibility size mismatch.');
assert(report.stage03_visibility.dual_cov_abs_diff < 1e-12, 'Stage03 visibility dual coverage mismatch.');

assert(report.stage04_window.lambda_abs_diff < 1e-10, 'Stage04 lambda mismatch.');
assert(report.stage04_window.t0_abs_diff < 1e-10, 'Stage04 t0 mismatch.');

assert(report.stage06_heading_family.count_match == 1, 'Stage06 heading family count mismatch.');
assert(report.stage06_heading_family.offsets_match == 1, 'Stage06 heading offsets mismatch.');
assert(report.stage06_heading_family.first_case_match == 1, 'Stage06 first case mismatch.');
assert(report.stage06_heading_family.last_case_match == 1, 'Stage06 last case mismatch.');
assert(report.stage06_heading_family.first_traj_size_match == 1, 'Stage06 first traj size mismatch.');

cmp05 = report.stage05_opend_smallset.compare_table;
assert(all(cmp05.pass_ratio_abs_diff < 1e-12), 'Stage05 OpenD pass ratio mismatch.');
assert(all(cmp05.feasible_match), 'Stage05 OpenD feasible flag mismatch.');
assert(all(cmp05.joint_margin_abs_diff < 1e-10), 'Stage05 OpenD joint margin mismatch.');

cmp09 = report.stage09_closedd_smallset.compare_table;
assert(all(cmp09.DG_abs_diff < 1e-12), 'Stage09 ClosedD DG mismatch.');
assert(all(cmp09.DA_abs_diff < 1e-12), 'Stage09 ClosedD DA mismatch.');
assert(all(cmp09.DT_abs_diff < 1e-12), 'Stage09 ClosedD DT mismatch.');
assert(all(cmp09.joint_margin_abs_diff < 1e-12), 'Stage09 ClosedD joint margin mismatch.');
assert(all(cmp09.pass_ratio_abs_diff < 1e-12), 'Stage09 ClosedD pass ratio mismatch.');
assert(all(cmp09.feasible_match), 'Stage09 ClosedD feasible flag mismatch.');

env_tbl = report.stage05_best_envelope.compare_table;
assert(all(env_tbl.best_pass_abs_diff < 1e-12), 'Stage05 best-pass envelope mismatch.');

hm_feas = report.stage05_heatmap_slice.feasible_compare;
assert(all(hm_feas.feasible_match), 'Stage05 feasible heatmap slice mismatch.');

hm_margin = report.stage05_heatmap_slice.margin_compare;
assert(all(hm_margin.joint_margin_abs_diff < 1e-10), 'Stage05 joint-margin heatmap slice mismatch.');

disp('assert_framework_vs_legacy_manual_regression passed.');
end
