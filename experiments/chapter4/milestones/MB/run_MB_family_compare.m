function comparison_result = run_MB_family_compare()
startup;

mgr_nominal = create_static_evaluation_manager(make_profile_MB_nominal());
out_nominal = mgr_nominal.run();

mgr_heading = create_static_evaluation_manager(make_profile_MB_heading());
out_heading = mgr_heading.run();

family_results = {out_nominal, out_heading};
comparison_result = task_family_comparison_service(family_results);

disp('[experiment] MB family comparison completed.');
disp(comparison_result.table);
end
