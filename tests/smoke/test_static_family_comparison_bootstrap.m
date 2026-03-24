function test_static_family_comparison_bootstrap()
startup;

mgr_nominal = create_static_evaluation_manager(make_profile_MB_nominal());
out_nominal = mgr_nominal.run();

mgr_heading = create_static_evaluation_manager(make_profile_MB_heading());
out_heading = mgr_heading.run();

comparison_result = task_family_comparison_service({out_nominal, out_heading});

assert(isstruct(comparison_result), 'comparison_result must be a struct.');
assert(isfield(comparison_result, 'table'), 'Missing comparison table.');

tbl = comparison_result.table;
assert(height(tbl) == 2, 'Expected two family rows.');

assert(all(ismember({'family_name','case_count','design_count','feasible_count', ...
    'feasible_ratio','min_Ns','max_joint_margin','min_joint_margin', ...
    'mean_joint_margin','best_design_id','best_rank_score'}, ...
    tbl.Properties.VariableNames)), ...
    'Missing expected comparison variables.');

assert(out_heading.task_family.case_count >= out_nominal.task_family.case_count, ...
    'Expected heading case count to be >= nominal case count.');

disp('test_static_family_comparison_bootstrap passed.');
end
