function test_ch5_minimal_mission_loop_bootstrap()
startup;

r = run_ch5_minimal_mission_loop();

assert(height(r.open_table) == 3, 'Expected 3 OpenD rows in Chapter 5 minimal loop.');
assert(height(r.closed_table) == 3, 'Expected 3 ClosedD rows in Chapter 5 minimal loop.');
assert(height(r.mission_table) == 3, 'Expected 3 mission rows in Chapter 5 minimal loop.');
assert(height(r.best_design_table) == 1, 'Expected a single best-design row.');

required = {'design_id', 'open_pass_ratio', 'closed_pass_ratio', 'open_joint_margin', 'closed_joint_margin', 'mission_score'};
assert(all(ismember(required, r.mission_table.Properties.VariableNames)), ...
    'Missing expected mission-table columns.');

assert(isfile(r.manifest_paths.mat_path), 'Missing Chapter 5 minimal manifest MAT.');
assert(isfile(r.manifest_paths.txt_path), 'Missing Chapter 5 minimal manifest TXT.');

disp('test_ch5_minimal_mission_loop_bootstrap passed.');
end
