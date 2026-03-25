function suite_result = run_framework_legacy_stage00_05_comparison_suite()
startup;

test_names = { ...
    'test_engine_scenario_stage01_casebank_vs_legacy', ...
    'test_engine_target_stage02_nominal_vs_legacy', ...
    'test_engine_heading_family_stage06_vs_legacy', ...
    'test_engine_resource_stage03_vs_legacy', ...
    'test_engine_visibility_stage03_vs_legacy', ...
    'test_engine_window_stage04_vs_legacy', ...
    'test_engine_inversion_opend_vs_legacy_stage05_smallset', ...
    'test_framework_best_envelope_vs_legacy_stage05', ...
    'test_framework_heatmap_slice_vs_legacy_stage05_grid', ...
    'test_framework_boundary_summary_consistency', ...
    'test_framework_fixed_path_curve_consistency'};

rows = repmat(struct('test_name', "", 'status', "", 'message', ""), numel(test_names), 1);

for k = 1:numel(test_names)
    rows(k).test_name = string(test_names{k});
    try
        feval(test_names{k});
        rows(k).status = "passed";
        rows(k).message = "";
    catch ME
        rows(k).status = "failed";
        rows(k).message = string(ME.message);
    end
end

summary_table = struct2table(rows);
suite_result = struct();
suite_result.summary_table = summary_table;
suite_result.all_passed = all(summary_table.status == "passed");

disp(summary_table);
end
