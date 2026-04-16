function T = ch5r_backfill_suite_state_metrics_from_mat(T)
%CH5R_BACKFILL_SUITE_STATE_METRICS_FROM_MAT
% Backfill SC/DC/LoC metrics from phase MAT files.

if ~istable(T)
    error('Input must be a table.');
end

all_cols = {'SC_steps','DC_steps','LoC_steps','SC_ratio','DC_ratio','LoC_ratio'};
for i = 1:numel(all_cols)
    c = all_cols{i};
    if ~ismember(c, T.Properties.VariableNames)
        T.(c) = nan(height(T),1);
    end
end

if ~ismember('mat_file', T.Properties.VariableNames)
    return;
end

for i = 1:height(T)
    need_any = any(~isfinite([T.SC_ratio(i), T.DC_ratio(i), T.LoC_ratio(i)]));
    if ~need_any
        continue;
    end

    mat_file = char(string(T.mat_file(i)));
    if isempty(mat_file) || ~isfile(mat_file)
        continue;
    end

    try
        S = load(mat_file);
    catch ME
        warning('[ch5r_backfill_suite_state_metrics_from_mat] Failed to load MAT: %s (%s)', mat_file, ME.message);
        continue;
    end

    try
        M = derive_ch5r_state_ratios(S);

        if isfinite(M.sc_steps),  T.SC_steps(i)  = M.sc_steps;  end
        if isfinite(M.dc_steps),  T.DC_steps(i)  = M.dc_steps;  end
        if isfinite(M.loc_steps), T.LoC_steps(i) = M.loc_steps; end

        if isfinite(M.sc_ratio),  T.SC_ratio(i)  = M.sc_ratio;  end
        if isfinite(M.dc_ratio),  T.DC_ratio(i)  = M.dc_ratio;  end
        if isfinite(M.loc_ratio), T.LoC_ratio(i) = M.loc_ratio; end

    catch ME
        warning('[ch5r_backfill_suite_state_metrics_from_mat] Derive failed for %s: %s', mat_file, ME.message);
    end
end
end
