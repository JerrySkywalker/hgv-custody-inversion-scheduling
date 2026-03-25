function test_framework_derive_bootstrap()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table;

slice_tbl = slice_truth_table(tbl, struct( ...
    'fixed_filters', struct('i_deg', 60), ...
    'keep_columns', {{'design_id','P','T','Ns','pass_ratio','is_feasible','joint_margin'}}));
envelope_tbl = build_best_envelope(tbl, 'Ns', 'pass_ratio', struct('i_deg', 60), 'max');
boundary_result = summarize_boundary(tbl);
curve_tbl = build_fixed_path_curve(tbl, struct('mode', 'diag_PT'));
scatter_tbl = build_design_point_scatter(tbl, 'Ns', 'pass_ratio', struct(), {'P','T'});

assert(~isempty(slice_tbl), 'Expected non-empty sliced truth table.');
assert(~isempty(envelope_tbl), 'Expected non-empty best envelope table.');
assert(isfield(boundary_result, 'summary_table'), 'Missing boundary summary table.');
assert(all(curve_tbl.P == curve_tbl.T), 'Fixed-path curve should satisfy P=T.');
assert(all(ismember({'x_value','y_value','point_label'}, scatter_tbl.Properties.VariableNames)), ...
    'Scatter table missing expected columns.');

disp('test_framework_derive_bootstrap passed.');
end
