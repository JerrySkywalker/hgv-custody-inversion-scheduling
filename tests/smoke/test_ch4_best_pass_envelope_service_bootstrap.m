function test_ch4_best_pass_envelope_service_bootstrap()
startup;

tbl = table( ...
    ["D1"; "D2"; "D3"; "D4"], ...
    [60; 60; 60; 70], ...
    [8; 10; 8; 6], ...
    [8; 6; 10; 6], ...
    [64; 60; 80; 36], ...
    [0.30; 0.70; 0.60; 0.90], ...
    [0.10; 0.40; 0.50; 0.20], ...
    'VariableNames', {'design_id', 'i_deg', 'P', 'T', 'Ns', 'pass_ratio', 'joint_margin'});

env = ch4_best_pass_envelope_service(tbl, struct('i_deg', 60));
env_tbl = env.envelope_table;

assert(height(env_tbl) == 3, 'Unexpected envelope point count.');

row60 = env_tbl(env_tbl.Ns == 60, :);
row64 = env_tbl(env_tbl.Ns == 64, :);
row80 = env_tbl(env_tbl.Ns == 80, :);

assert(height(row60) == 1 && abs(row60.best_pass - 0.70) < 1e-12, 'Ns=60 best_pass mismatch.');
assert(string(row60.argmax_design_id) == "D2", 'Ns=60 argmax design mismatch.');
assert(height(row64) == 1 && abs(row64.best_pass - 0.30) < 1e-12, 'Ns=64 best_pass mismatch.');
assert(height(row80) == 1 && abs(row80.best_pass - 0.60) < 1e-12, 'Ns=80 best_pass mismatch.');

disp('test_ch4_best_pass_envelope_service_bootstrap passed.');
end
