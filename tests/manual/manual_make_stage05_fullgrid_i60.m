function rows = manual_make_stage05_fullgrid_i60()
cfg = default_params();

P_list = cfg.stage05.P_grid;
T_list = cfg.stage05.T_grid;

idx = 0;
rows = repmat(struct(), numel(P_list) * numel(T_list), 1);

for i = 1:numel(P_list)
    for j = 1:numel(T_list)
        idx = idx + 1;

        P = P_list(i);
        T = T_list(j);

        rows(idx).design_id = sprintf('F%02d_P%d_T%d', idx, P, T);
        rows(idx).h_km = cfg.stage05.h_fixed_km;
        rows(idx).i_deg = 60;
        rows(idx).P = P;
        rows(idx).T = T;
        rows(idx).F = cfg.stage05.F_fixed;
        rows(idx).Ns = P * T;
    end
end
end
