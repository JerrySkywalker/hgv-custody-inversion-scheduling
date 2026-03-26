function assert_stage05_opend_legacy_reproduction_compare()
startup;

out = manual_smoke_stage05_opend_legacy_reproduction_compare();

best_cmp = out.best_pass_compare;
hm_cmp = out.heatmap_compare;

assert(all(best_cmp.pass_abs_diff == 0 | isnan(best_cmp.pass_abs_diff)), ...
    'best_pass_by_Ns does not exactly match legacy.');

assert(all(hm_cmp.abs_diff < 1e-6 | isnan(hm_cmp.abs_diff)), ...
    'geometry_heatmap_i60 differs from legacy by more than tolerance.');

disp('assert_stage05_opend_legacy_reproduction_compare passed.');
end
