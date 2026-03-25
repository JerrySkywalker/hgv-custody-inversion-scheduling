function result = run_MB_nominal_validation_stage05()
startup;

profile = make_profile_MB_nominal_validation_stage05();
mgr = create_static_evaluation_manager(profile);
result = mgr.run();

disp('[validation] MB nominal validation stage05 run completed.');
disp(result.truth_result.table(:, {'design_id','h_km','i_deg','P','T','Ns','pass_ratio','is_feasible','joint_margin'}));
end
