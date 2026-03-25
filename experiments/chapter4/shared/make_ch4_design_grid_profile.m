function grid_profile = make_ch4_design_grid_profile()
grid_profile = struct();

grid_profile.bootstrap = struct();
grid_profile.bootstrap.rows = [ ...
    make_row('D0001', 8,  8,  800, 60, 0), ...
    make_row('D0002', 8, 10,  800, 60, 0), ...
    make_row('D0003', 10, 8,  800, 60, 0) ...
];

grid_profile.validation_stage05 = struct();
grid_profile.validation_stage05.rows = [ ...
    make_row('V0501', 8,  8, 1000, 60, 0), ...
    make_row('V0502', 8, 10, 1000, 60, 0), ...
    make_row('V0503', 10, 8, 1000, 60, 0) ...
];

grid_profile.validation_stage06 = struct();
grid_profile.validation_stage06.rows = [ ...
    make_row('H0601', 8,  8, 1000, 60, 0), ...
    make_row('H0602', 8, 10, 1000, 60, 0), ...
    make_row('H0603', 10, 8, 1000, 60, 0) ...
];

grid_profile.small_formal = struct();
grid_profile.small_formal.P_set = [4, 6, 8, 10];
grid_profile.small_formal.T_set = [4, 6, 8, 10];
grid_profile.small_formal.h_set_km = 1000;
grid_profile.small_formal.i_set_deg = 60;
grid_profile.small_formal.F_set = 0;
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
