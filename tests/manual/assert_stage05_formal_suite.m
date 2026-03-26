function assert_stage05_formal_suite()
startup;

out = manual_smoke_stage05_formal_suite();
assert_stage05_formal_suite_result(out);

disp('assert_stage05_formal_suite passed.');
end
