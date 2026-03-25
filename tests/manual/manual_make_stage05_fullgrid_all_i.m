function rows = manual_make_stage05_fullgrid_all_i()
cfg = default_params();

i_list = cfg.stage05.i_grid_deg;
P_list = cfg.stage05.P_grid;
T_list = cfg.stage05.T_grid;

idx = 0;
rows = repmat(struct(), numel(i_list) * numel(P_list) * numel(T_list), 1);

for ii = 1:numel(i_list)
    for i = 1:numel(P_list)
        for j = 1:numel(T_list)
            idx = idx + 1;

            i_deg = i_list(ii);
            P = P_list(i);
            T = T_list(j);

            rows(idx).design_id = sprintf('A%03d_i%d_P%d_T%d', idx, i_deg, P, T);
            rows(idx).h_km = cfg.stage05.h_fixed_km;
            rows(idx).i_deg = i_deg;
            rows(idx).P = P;
            rows(idx).T = T;
            rows(idx).F = cfg.stage05.F_fixed;
            rows(idx).Ns = P * T;
        end
    end
end
end
