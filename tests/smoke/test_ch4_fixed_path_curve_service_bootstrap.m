function test_ch4_fixed_path_curve_service_bootstrap()
startup;

tbl = table( ...
    ["A"; "B"; "C"; "D"], ...
    [4; 4; 6; 8], ...
    [4; 6; 6; 4], ...
    [16; 24; 36; 32], ...
    [0.1; 0.2; 0.3; 0.4], ...
    'VariableNames', {'design_id', 'P', 'T', 'Ns', 'pass_ratio'});

r_eq = ch4_fixed_path_curve_service(tbl, struct('mode', 'P_equals_T'));
assert(height(r_eq.curve_table) == 2, 'Expected two P==T points.');
assert(all(r_eq.curve_table.P == r_eq.curve_table.T), 'P==T filter mismatch.');

r_p4 = ch4_fixed_path_curve_service(tbl, struct('mode', 'fixed_P', 'P', 4));
assert(height(r_p4.curve_table) == 2, 'Expected two fixed-P points.');
assert(all(r_p4.curve_table.P == 4), 'Fixed-P filter mismatch.');

disp('test_ch4_fixed_path_curve_service_bootstrap passed.');
end
