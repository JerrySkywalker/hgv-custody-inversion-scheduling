function run_smoke_tests_ch4()
startup;

disp('=== Running Chapter 4 smoke tests ===');

test_static_manager_bootstrap;
test_static_heading_master_run_bootstrap;
test_static_slice_service_bootstrap;
test_static_family_comparison_bootstrap;
test_static_artifact_service_bootstrap;
test_static_artifact_manifest_bootstrap;
test_static_minimum_artifact_bootstrap;
test_static_nominal_master_run_bootstrap;
test_static_compare_master_run_bootstrap;

disp('=== All Chapter 4 smoke tests passed ===');
end
