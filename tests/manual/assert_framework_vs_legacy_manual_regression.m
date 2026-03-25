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

% ------------------------------------------------------------
% Stage05 OpenD small-set
% ------------------------------------------------------------
cmp05 = report.stage05_opend_smallset.compare_table;
assert(all(cmp05.pass_ratio_abs_diff < 1e-12), 'Stage05 OpenD small-set pass ratio mismatch.');
assert(all(cmp05.feasible_match), 'Stage05 OpenD small-set feasible flag mismatch.');
assert(all(cmp05.geometry_margin_abs_diff < 1e-10), 'Stage05 OpenD small-set geometry margin mismatch.');

% ------------------------------------------------------------
% Stage09 ClosedD small-set
% ------------------------------------------------------------
cmp09 = report.stage09_closedd_smallset.compare_table;
assert(all(cmp09.DG_abs_diff < 1e-12), 'Stage09 ClosedD DG mismatch.');
assert(all(cmp09.DA_abs_diff < 1e-12), 'Stage09 ClosedD DA mismatch.');
assert(all(cmp09.DT_abs_diff < 1e-12), 'Stage09 ClosedD DT mismatch.');
assert(all(cmp09.joint_margin_abs_diff < 1e-12), 'Stage09 ClosedD joint margin mismatch.');
assert(all(cmp09.pass_ratio_abs_diff < 1e-12), 'Stage09 ClosedD pass ratio mismatch.');
assert(all(cmp09.feasible_match), 'Stage09 ClosedD feasible flag mismatch.');

% ------------------------------------------------------------
% Stage05 product-level small checks
% ------------------------------------------------------------
env_tbl = report.stage05_best_envelope.compare_table;
assert(all(env_tbl.best_pass_abs_diff < 1e-12), 'Stage05 best-pass envelope mismatch.');

hm_feas = report.stage05_heatmap_slice.feasible_compare;
assert(all(hm_feas.feasible_match), 'Stage05 feasible heatmap slice mismatch.');

hm_margin = report.stage05_heatmap_slice.margin_compare;
assert(all(hm_margin.joint_margin_abs_diff < 1e-10), 'Stage05 joint-margin heatmap slice mismatch.');

% ------------------------------------------------------------
% Stage05 OpenD full-grid i=60
% ------------------------------------------------------------
fg_i60 = report.stage05_opend_fullgrid_i60.compare_table;
assert(all(fg_i60.pass_ratio_abs_diff < 1e-12), 'Stage05 OpenD full-grid i60 pass ratio mismatch.');
assert(all(fg_i60.feasible_match), 'Stage05 OpenD full-grid i60 feasible flag mismatch.');
assert(all(fg_i60.geometry_margin_abs_diff < 1e-10), 'Stage05 OpenD full-grid i60 geometry margin mismatch.');

fg_env_i60 = report.stage05_best_envelope_fullgrid_i60.compare_table;
assert(all(fg_env_i60.best_pass_abs_diff < 1e-12), 'Stage05 best-envelope full-grid i60 mismatch.');
if ismember('best_geometry_margin_abs_diff', fg_env_i60.Properties.VariableNames)
    assert(all(fg_env_i60.best_geometry_margin_abs_diff < 1e-10), ...
        'Stage05 best-envelope full-grid i60 geometry margin mismatch.');
end

fg_hm_i60_feas = report.stage05_heatmap_fullgrid_i60.feasible_compare;
assert(all(fg_hm_i60_feas.feasible_match), 'Stage05 heatmap full-grid i60 feasible mismatch.');

fg_hm_i60_margin = report.stage05_heatmap_fullgrid_i60.margin_compare;
assert(all(fg_hm_i60_margin.geometry_margin_abs_diff < 1e-10), ...
    'Stage05 heatmap full-grid i60 geometry margin mismatch.');

% ------------------------------------------------------------
% Stage05 OpenD full-grid all-i
% NOTE: allow 1e-6 for geometry margin because high-incidence, zero-nearby
% boundary points show numeric-path differences without changing feasibility.
% ------------------------------------------------------------
fg_all = report.stage05_opend_fullgrid_all_i.compare_table;
assert(all(fg_all.pass_ratio_abs_diff < 1e-12), 'Stage05 OpenD full-grid all-i pass ratio mismatch.');
assert(all(fg_all.feasible_match), 'Stage05 OpenD full-grid all-i feasible flag mismatch.');
assert(all(fg_all.geometry_margin_abs_diff < 1e-6), ...
    'Stage05 OpenD full-grid all-i geometry margin mismatch.');

fg_env_all = report.stage05_best_envelope_fullgrid_all_i.compare_table;
assert(all(fg_env_all.best_pass_abs_diff < 1e-12), ...
    'Stage05 best-envelope full-grid all-i mismatch.');
if ismember('best_geometry_margin_abs_diff', fg_env_all.Properties.VariableNames)
    mask = ~isnan(fg_env_all.best_geometry_margin_abs_diff);
    assert(all(fg_env_all.best_geometry_margin_abs_diff(mask) < 1e-6), ...
        'Stage05 best-envelope full-grid all-i geometry margin mismatch.');
end

fg_hm_all_feas = report.stage05_heatmap_fullgrid_all_i.feasible_compare;
assert(all(fg_hm_all_feas.feasible_match), ...
    'Stage05 heatmap full-grid all-i feasible mismatch.');

fg_hm_all_margin = report.stage05_heatmap_fullgrid_all_i.margin_compare;
assert(all(fg_hm_all_margin.geometry_margin_abs_diff < 1e-6), ...
    'Stage05 heatmap full-grid all-i geometry margin mismatch.');

disp('assert_framework_vs_legacy_manual_regression passed.');
end
