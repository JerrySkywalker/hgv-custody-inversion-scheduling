function result = run_MB_heading_validation_stage06()
startup;

profile = make_profile_MB_heading_validation_stage06();
mgr = create_static_evaluation_manager(profile);
result = mgr.run();

disp('[validation] MB heading validation stage06 run completed.');
disp(result.truth_result.table(:, {'design_id','h_km','i_deg','P','T','Ns','gamma_eff_scalar','gamma_source','Tw_s','pass_ratio','is_feasible','joint_margin'}));
end
