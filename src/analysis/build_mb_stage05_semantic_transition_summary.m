function summary_table = build_mb_stage05_semantic_transition_summary(eval_table, envelope_table, h_km, i_grid_deg)
%BUILD_MB_STAGE05_SEMANTIC_TRANSITION_SUMMARY Summarize inclination-wise frontier points for Stage05 semantics.

rows = table();

for idx = 1:numel(i_grid_deg)
    i_deg = i_grid_deg(idx);
    Ti = eval_table(eval_table.i_deg == i_deg, :);
    Ei = envelope_table(envelope_table.i_deg == i_deg, :);

    first_Ns_pass1 = NaN;
    hit_pass = Ei(Ei.max_pass_ratio >= 1 - 1e-12, :);
    if ~isempty(hit_pass)
        first_Ns_pass1 = hit_pass.Ns(1);
    end

    frontier_Ns = NaN;
    frontier_D_G_min = NaN;
    frontier_P = NaN;
    frontier_T = NaN;
    feasible_rows = Ti(Ti.feasible, :);
    if ~isempty(feasible_rows)
        minNs_i = min(feasible_rows.Ns);
        frontier_candidates = feasible_rows(feasible_rows.Ns == minNs_i, :);
        [~, best_idx] = max(frontier_candidates.D_G_min);
        best_row = frontier_candidates(best_idx, :);
        frontier_Ns = best_row.Ns;
        frontier_D_G_min = best_row.D_G_min;
        frontier_P = best_row.P;
        frontier_T = best_row.T;
    end

    row = table(h_km, i_deg, first_Ns_pass1, frontier_Ns, frontier_D_G_min, frontier_P, frontier_T, ...
        'VariableNames', {'h_km', 'i_deg', 'first_Ns_pass1', 'frontier_Ns', 'frontier_D_G_min', 'frontier_P', 'frontier_T'});
    rows = [rows; row]; %#ok<AGROW>
end

summary_table = sortrows(rows, 'i_deg');
end
