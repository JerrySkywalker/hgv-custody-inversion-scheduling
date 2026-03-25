function result = run_MB_nominal_small_formal()
startup;

profile = make_profile_MB_nominal_small_formal();
engine_result = run_engine_opend_nominal_small_formal();

out = struct();
out.truth_result = engine_result.truth_result;
out.minimum_solution_result = minimum_solution_service(engine_result.truth_result);
out.meta = struct();
out.meta.source = 'engine_opend';
out.meta.runner = 'run_engine_opend_nominal_small_formal';
out.engine_result = engine_result;

result = struct();
result.profile = profile;
result.out = out;
result.engine_result = engine_result;

disp('[experiment] MB nominal small-formal run completed.');
disp(out.truth_result.table(:, {'design_id','h_km','i_deg','P','T','Ns','pass_ratio','is_feasible','joint_margin'}));
end
