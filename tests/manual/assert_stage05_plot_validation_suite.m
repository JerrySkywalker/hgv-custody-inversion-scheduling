function assert_stage05_plot_validation_suite()
startup;

out = manual_smoke_stage05_plot_validation_suite();
assert_stage05_plot_validation_suite_result(out);

disp('assert_stage05_plot_validation_suite passed.');
end
