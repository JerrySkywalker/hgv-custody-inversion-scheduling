function stats = aggregate_stage14_ns_envelope_stats(envelope_table)
%AGGREGATE_STAGE14_NS_ENVELOPE_STATS
% Aggregate one Stage14 Ns-envelope table over RAAN_rel.
%
% Input:
%   envelope_table with columns:
%     h_km, i_deg, F, Ns, RAAN_deg,
%     DG_env_max, best_P_for_DG, best_T_for_DG,
%     pass_env_max, best_P_for_pass, best_T_for_pass
%
% Output:
%   stats struct containing:
%     summary_table
%     best_PT_of_raan_mean_DG
%     best_PT_of_raan_min_DG
%     best_PT_of_raan_mean_pass
%     best_PT_of_raan_min_pass

    assert(height(envelope_table) >= 1, 'envelope_table is empty.');

    requiredVars = { ...
        'h_km','i_deg','F','Ns','RAAN_deg', ...
        'DG_env_max','best_P_for_DG','best_T_for_DG', ...
        'pass_env_max','best_P_for_pass','best_T_for_pass'};
    for k = 1:numel(requiredVars)
        assert(ismember(requiredVars{k}, envelope_table.Properties.VariableNames), ...
            'Missing required column: %s', requiredVars{k});
    end

    envelope_table = sortrows(envelope_table, 'RAAN_deg');

    dg_vec = envelope_table.DG_env_max;
    pass_vec = envelope_table.pass_env_max;

    dg_mean = mean(dg_vec, 'omitnan');
    dg_min  = min(dg_vec, [], 'omitnan');
    dg_max  = max(dg_vec, [], 'omitnan');
    dg_span = dg_max - dg_min;
    dg_std  = std(dg_vec, 0, 'omitnan');

    pass_mean = mean(pass_vec, 'omitnan');
    pass_min  = min(pass_vec, [], 'omitnan');
    pass_max  = max(pass_vec, [], 'omitnan');
    pass_span = pass_max - pass_min;
    pass_std  = std(pass_vec, 0, 'omitnan');

    [~, idx_dg_min] = min(dg_vec, [], 'omitnan');
    [~, idx_pass_min] = min(pass_vec, [], 'omitnan');

    best_PT_of_raan_mean_DG = local_mode_pair(envelope_table.best_P_for_DG, envelope_table.best_T_for_DG);
    best_PT_of_raan_mean_pass = local_mode_pair(envelope_table.best_P_for_pass, envelope_table.best_T_for_pass);

    best_PT_of_raan_min_DG = struct();
    best_PT_of_raan_min_DG.P = envelope_table.best_P_for_DG(idx_dg_min);
    best_PT_of_raan_min_DG.T = envelope_table.best_T_for_DG(idx_dg_min);
    best_PT_of_raan_min_DG.RAAN_deg = envelope_table.RAAN_deg(idx_dg_min);
    best_PT_of_raan_min_DG.value = envelope_table.DG_env_max(idx_dg_min);

    best_PT_of_raan_min_pass = struct();
    best_PT_of_raan_min_pass.P = envelope_table.best_P_for_pass(idx_pass_min);
    best_PT_of_raan_min_pass.T = envelope_table.best_T_for_pass(idx_pass_min);
    best_PT_of_raan_min_pass.RAAN_deg = envelope_table.RAAN_deg(idx_pass_min);
    best_PT_of_raan_min_pass.value = envelope_table.pass_env_max(idx_pass_min);

    summary_table = table( ...
        envelope_table.h_km(1), ...
        envelope_table.i_deg(1), ...
        envelope_table.F(1), ...
        envelope_table.Ns(1), ...
        dg_mean, dg_min, dg_max, dg_span, dg_std, ...
        pass_mean, pass_min, pass_max, pass_span, pass_std, ...
        best_PT_of_raan_mean_DG.P, best_PT_of_raan_mean_DG.T, ...
        best_PT_of_raan_min_DG.P, best_PT_of_raan_min_DG.T, best_PT_of_raan_min_DG.RAAN_deg, ...
        best_PT_of_raan_mean_pass.P, best_PT_of_raan_mean_pass.T, ...
        best_PT_of_raan_min_pass.P, best_PT_of_raan_min_pass.T, best_PT_of_raan_min_pass.RAAN_deg, ...
        'VariableNames', { ...
            'h_km','i_deg','F','Ns', ...
            'DG_env_mean','DG_env_min','DG_env_max','DG_env_span','DG_env_std', ...
            'pass_env_mean','pass_env_min','pass_env_max','pass_env_span','pass_env_std', ...
            'best_P_of_raan_mean_DG','best_T_of_raan_mean_DG', ...
            'best_P_of_raan_min_DG','best_T_of_raan_min_DG','RAAN_of_raan_min_DG', ...
            'best_P_of_raan_mean_pass','best_T_of_raan_mean_pass', ...
            'best_P_of_raan_min_pass','best_T_of_raan_min_pass','RAAN_of_raan_min_pass' ...
        });

    stats = struct();
    stats.summary_table = summary_table;
    stats.best_PT_of_raan_mean_DG = best_PT_of_raan_mean_DG;
    stats.best_PT_of_raan_min_DG = best_PT_of_raan_min_DG;
    stats.best_PT_of_raan_mean_pass = best_PT_of_raan_mean_pass;
    stats.best_PT_of_raan_min_pass = best_PT_of_raan_min_pass;
end

function pair = local_mode_pair(P_vec, T_vec)
    PT = [P_vec(:), T_vec(:)];
    [uPT, ~, ic] = unique(PT, 'rows');
    counts = accumarray(ic, 1);
    [~, idx] = max(counts);

    pair = struct();
    pair.P = uPT(idx,1);
    pair.T = uPT(idx,2);
    pair.count = counts(idx);
end
