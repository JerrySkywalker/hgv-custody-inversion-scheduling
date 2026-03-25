function rows = manual_make_stage05_representative_grid()
P_list = [8, 10, 12];
T_list = [8, 10, 12];

idx = 0;
rows = repmat(struct(), numel(P_list) * numel(T_list), 1);

for i = 1:numel(P_list)
    for j = 1:numel(T_list)
        idx = idx + 1;

        P = P_list(i);
        T = T_list(j);

        rows(idx).design_id = sprintf('R%02d_P%d_T%d', idx, P, T);
        rows(idx).h_km = 1000;
        rows(idx).i_deg = 60;
        rows(idx).P = P;
        rows(idx).T = T;
        rows(idx).F = 0;
        rows(idx).Ns = P * T;
    end
end
end
