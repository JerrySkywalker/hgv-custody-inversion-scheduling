function assert_stage05_plot_validation_suite_compare_result(cmp)
best_max = max(cmp.best_pass_compare.pass_abs_diff, [], 'omitnan');
hm_max = max(cmp.heatmap_compare.abs_diff, [], 'omitnan');

assert(best_max == 0 || isnan(best_max), ...
    'Best-pass plotting source does not exactly match legacy.');

assert(hm_max < 1e-6 || isnan(hm_max), ...
    'Heatmap plotting source differs from legacy by more than tolerance.');

disp('assert_stage05_plot_validation_suite_compare_result passed.');
end
