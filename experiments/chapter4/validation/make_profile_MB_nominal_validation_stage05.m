function profile = make_profile_MB_nominal_validation_stage05()
profile = struct();
profile.name = 'MB_nominal_validation_stage05';
profile.mode = 'static';
profile.task_family = 'nominal';

profile.runtime = struct();
profile.runtime.max_cases = 1;
profile.runtime.max_designs = 3;

profile.gamma_eff_scalar = 19748;
profile.gamma_source = 'stage04_nominal_quantile';

profile.design_pool = struct();
profile.design_pool.rows = [ ...
    make_row('V0501', 8,  8,  1000, 60, 0), ...
    make_row('V0502', 8, 10,  1000, 60, 0), ...
    make_row('V0503', 10, 8,  1000, 60, 0) ...
];
end

function row = make_row(design_id, P, T, h_km, i_deg, F)
row = struct();
row.design_id = design_id;
row.P = P;
row.T = T;
row.h_km = h_km;
row.i_deg = i_deg;
row.F = F;
row.Ns = P * T;
end
