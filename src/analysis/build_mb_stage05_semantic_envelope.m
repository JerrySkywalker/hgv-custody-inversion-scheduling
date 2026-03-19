function envelope_table = build_mb_stage05_semantic_envelope(eval_table, h_km, i_grid_deg)
%BUILD_MB_STAGE05_SEMANTIC_ENVELOPE Aggregate Stage05-style pass-ratio and D_G envelopes over N_s.

Ns_list = unique(eval_table.Ns(:), 'sorted');
rows = table();

for idx_i = 1:numel(i_grid_deg)
    i_deg = i_grid_deg(idx_i);
    Ti = eval_table(eval_table.i_deg == i_deg, :);
    for idx_ns = 1:numel(Ns_list)
        Ns = Ns_list(idx_ns);
        Tij = Ti(Ti.Ns == Ns, :);
        if isempty(Tij)
            continue;
        end

        feasible_rows = Tij(Tij.feasible, :);
        min_feasible_D_G = NaN;
        min_feasible_P = NaN;
        min_feasible_T = NaN;
        if ~isempty(feasible_rows)
            [~, min_idx] = min(feasible_rows.D_G_min);
            min_feasible_D_G = feasible_rows.D_G_min(min_idx);
            min_feasible_P = feasible_rows.P(min_idx);
            min_feasible_T = feasible_rows.T(min_idx);
        end

        row = table(h_km, i_deg, Ns, ...
            max(Tij.pass_ratio), ...
            max(Tij.D_G_min), ...
            min_feasible_D_G, ...
            min_feasible_P, ...
            min_feasible_T, ...
            'VariableNames', {'h_km', 'i_deg', 'Ns', 'max_pass_ratio', 'max_D_G_min', ...
            'min_feasible_D_G_min', 'min_feasible_P', 'min_feasible_T'});
        rows = [rows; row]; %#ok<AGROW>
    end
end

envelope_table = sortrows(rows, {'i_deg', 'Ns'});
end
