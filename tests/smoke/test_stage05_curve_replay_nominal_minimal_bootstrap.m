function test_stage05_curve_replay_nominal_minimal_bootstrap()
startup;

result = run_stage05_curve_replay_nominal_minimal();

assert(isfield(result, 'replay_result'), 'Missing replay_result.');
assert(isfield(result.replay_result, 'curve_table'), 'Missing replay curve_table.');
assert(isfield(result.replay_result, 'summary_table'), 'Missing replay summary_table.');
assert(height(result.replay_result.curve_table) >= 1, 'Expected non-empty replay curve.');

disp('test_stage05_curve_replay_nominal_minimal_bootstrap passed.');
end
