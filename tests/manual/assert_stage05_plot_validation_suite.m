function assert_stage05_plot_validation_suite()
startup;

out = manual_smoke_stage05_plot_validation_suite();
assert_stage05_plot_validation_suite_result(out);
assert_stage05_plot_validation_suite_compare_result(out.compare);

disp('assert_stage05_plot_validation_suite passed.');
end
