function result = run_MB_nominal_small_formal()
startup;

profile = make_profile_MB_nominal_small_formal();
mgr = create_static_evaluation_manager(profile);
out = mgr.run();

result = struct();
result.profile = profile;
result.out = out;

disp('[experiment] MB nominal small-formal run completed.');
disp(out.truth_result.table(:, {'design_id','h_km','i_deg','P','T','Ns','pass_ratio','is_feasible','joint_margin'}));
end
