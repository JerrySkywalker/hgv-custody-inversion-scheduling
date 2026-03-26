function assert_stage05_opend_legacy_reproduction_compare_result(out)
best_cmp = out.best_pass_compare;
hm_cmp = out.heatmap_compare;

assert(~any(isnan(best_cmp.Ns)), ...
    'best_pass_compare has NaN in Ns.');

assert(~any(isnan(best_cmp.pass_ratio)), ...
    'best_pass_compare has missing framework pass_ratio values.');

assert(~any(isnan(best_cmp.legacy_pass_ratio)), ...
    'best_pass_compare has missing legacy pass_ratio values.');

assert(~any(isnan(best_cmp.pass_abs_diff)), ...
    'best_pass_compare has NaN diff values, indicating incomplete compare coverage.');

assert(all(best_cmp.pass_abs_diff == 0), ...
    'best_pass_by_Ns does not exactly match legacy.');

assert(~any(isnan(hm_cmp.P)), ...
    'heatmap_compare has NaN in P.');

assert(~any(isnan(hm_cmp.T)), ...
    'heatmap_compare has NaN in T.');

assert(~any(isnan(hm_cmp.framework_DG_rob)), ...
    'heatmap_compare has missing framework DG values.');

assert(~any(isnan(hm_cmp.legacy_DG_rob)), ...
    'heatmap_compare has missing legacy DG values.');

assert(~any(isnan(hm_cmp.abs_diff)), ...
    'heatmap_compare has NaN diff values, indicating incomplete compare coverage.');

assert(all(hm_cmp.abs_diff < 1e-6), ...
    'geometry_heatmap_i60 differs from legacy by more than tolerance.');

disp('assert_stage05_opend_legacy_reproduction_compare_result passed.');
end
