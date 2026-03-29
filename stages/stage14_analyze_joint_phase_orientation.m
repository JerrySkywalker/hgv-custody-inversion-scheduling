function out = stage14_analyze_joint_phase_orientation(summary_table, opts)
%STAGE14_ANALYZE_JOINT_PHASE_ORIENTATION
% Official reusable analysis interface for Stage14.4 B-line statistics.
%
% Inputs:
%   summary_table : table with columns
%       F, RAAN_deg, pass_ratio, D_G_mean, D_G_min
%
% Outputs:
%   out.bestF_by_RAAN
%   out.robust_stats_by_F
%   out.dgmin_switch_table
%   out.periodicity_F0
%   out.key_summary

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    local = struct();
    local.scope_name = "A1";
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    assert(istable(summary_table) && ~isempty(summary_table), ...
        'summary_table must be a non-empty table.');

    req = {'F','RAAN_deg','pass_ratio','D_G_mean','D_G_min'};
    for k = 1:numel(req)
        assert(any(strcmp(summary_table.Properties.VariableNames, req{k})), ...
            'summary_table missing required variable: %s', req{k});
    end

    F_values = unique(summary_table.F(:))';
    RAAN_values = unique(summary_table.RAAN_deg(:))';

    out = struct();
    out.scope_name = local.scope_name;
    out.bestF_by_RAAN = i_build_bestF_table(summary_table, RAAN_values);
    out.robust_stats_by_F = i_build_robust_stats_table(summary_table, F_values);
    out.dgmin_switch_table = i_build_dgmin_switch_table(out.bestF_by_RAAN, F_values);
    out.periodicity_F0 = i_build_periodicity(summary_table);
    out.key_summary = i_build_key_summary(out.robust_stats_by_F);

    if ~local.quiet
        fprintf('\n=== Stage14.4 Analysis Interface ===\n');
        fprintf('scope              : %s\n', local.scope_name);
        fprintf('RAAN count         : %d\n', numel(RAAN_values));
        fprintf('F count            : %d\n', numel(F_values));
        fprintf('bestF rows         : %d\n', height(out.bestF_by_RAAN));
        fprintf('robust stats rows  : %d\n', height(out.robust_stats_by_F));
    end
end

function bestF_table = i_build_bestF_table(summary_table, RAAN_values)
    nR = numel(RAAN_values);

    RAAN_deg = zeros(nR,1);
    bestF_pass_ratio = zeros(nR,1);
    best_pass_ratio = zeros(nR,1);
    bestF_DG_mean = zeros(nR,1);
    best_DG_mean = zeros(nR,1);
    bestF_DG_min = zeros(nR,1);
    best_DG_min = zeros(nR,1);

    for i = 1:nR
        raan = RAAN_values(i);
        rows = summary_table(summary_table.RAAN_deg == raan, :);

        [best_pass_ratio(i), idx1] = max(rows.pass_ratio);
        bestF_pass_ratio(i) = rows.F(idx1(1));

        [best_DG_mean(i), idx2] = max(rows.D_G_mean);
        bestF_DG_mean(i) = rows.F(idx2(1));

        [best_DG_min(i), idx3] = max(rows.D_G_min);
        bestF_DG_min(i) = rows.F(idx3(1));

        RAAN_deg(i) = raan;
    end

    bestF_table = table( ...
        RAAN_deg, ...
        bestF_pass_ratio, best_pass_ratio, ...
        bestF_DG_mean, best_DG_mean, ...
        bestF_DG_min, best_DG_min, ...
        'VariableNames', { ...
            'RAAN_deg', ...
            'bestF_pass_ratio', 'best_pass_ratio', ...
            'bestF_DG_mean', 'best_DG_mean', ...
            'bestF_DG_min', 'best_DG_min'});
end

function robust_stats_table = i_build_robust_stats_table(summary_table, F_values)
    nF = numel(F_values);

    F = zeros(nF,1);
    pass_ratio_mean = zeros(nF,1);
    pass_ratio_min = zeros(nF,1);
    pass_ratio_max = zeros(nF,1);
    pass_ratio_span = zeros(nF,1);
    DG_mean_mean = zeros(nF,1);
    DG_mean_min = zeros(nF,1);
    DG_mean_max = zeros(nF,1);
    DG_mean_span = zeros(nF,1);
    DG_min_mean = zeros(nF,1);
    DG_min_min = zeros(nF,1);
    DG_min_max = zeros(nF,1);
    DG_min_span = zeros(nF,1);
    pass_ratio_std = zeros(nF,1);
    DG_mean_std = zeros(nF,1);
    DG_min_std = zeros(nF,1);

    for i = 1:nF
        f = F_values(i);
        rows = summary_table(summary_table.F == f, :);

        F(i) = f;

        pass_ratio_mean(i) = mean(rows.pass_ratio);
        pass_ratio_min(i)  = min(rows.pass_ratio);
        pass_ratio_max(i)  = max(rows.pass_ratio);
        pass_ratio_span(i) = pass_ratio_max(i) - pass_ratio_min(i);
        pass_ratio_std(i)  = std(rows.pass_ratio);

        DG_mean_mean(i) = mean(rows.D_G_mean);
        DG_mean_min(i)  = min(rows.D_G_mean);
        DG_mean_max(i)  = max(rows.D_G_mean);
        DG_mean_span(i) = DG_mean_max(i) - DG_mean_min(i);
        DG_mean_std(i)  = std(rows.D_G_mean);

        DG_min_mean(i) = mean(rows.D_G_min);
        DG_min_min(i)  = min(rows.D_G_min);
        DG_min_max(i)  = max(rows.D_G_min);
        DG_min_span(i) = DG_min_max(i) - DG_min_min(i);
        DG_min_std(i)  = std(rows.D_G_min);
    end

    robust_stats_table = table( ...
        F, ...
        pass_ratio_mean, pass_ratio_min, pass_ratio_max, pass_ratio_span, ...
        DG_mean_mean, DG_mean_min, DG_mean_max, DG_mean_span, ...
        DG_min_mean, DG_min_min, DG_min_max, DG_min_span, ...
        pass_ratio_std, DG_mean_std, DG_min_std, ...
        'VariableNames', { ...
            'F', ...
            'pass_ratio_mean', 'pass_ratio_min', 'pass_ratio_max', 'pass_ratio_span', ...
            'DG_mean_mean', 'DG_mean_min', 'DG_mean_max', 'DG_mean_span', ...
            'DG_min_mean', 'DG_min_min', 'DG_min_max', 'DG_min_span', ...
            'pass_ratio_std', 'DG_mean_std', 'DG_min_std'});
end

function dgmin_switch_table = i_build_dgmin_switch_table(bestF_table, F_values)
    counts = zeros(numel(F_values), 1);
    for i = 1:numel(F_values)
        counts(i) = sum(bestF_table.bestF_DG_min == F_values(i));
    end
    dgmin_switch_table = table(F_values(:), counts, ...
        'VariableNames', {'F', 'bestF_DG_min_count_over_RAAN'});
end

function periodicity = i_build_periodicity(summary_table)
    rows = summary_table(summary_table.F == 0, :);
    periodicity = struct();
    periodicity.pass_ratio = i_metric_periodicity(rows.RAAN_deg, rows.pass_ratio);
    periodicity.DG_mean    = i_metric_periodicity(rows.RAAN_deg, rows.D_G_mean);
    periodicity.DG_min     = i_metric_periodicity(rows.RAAN_deg, rows.D_G_min);
end

function out = i_metric_periodicity(raan_deg, values)
    out = struct();
    out.unique_values_count = numel(unique(round(values, 12)));
    out.span = max(values) - min(values);
    out.max_abs_delta45  = i_shift_compare(raan_deg, values, 45);
    out.max_abs_delta90  = i_shift_compare(raan_deg, values, 90);
    out.max_abs_delta180 = i_shift_compare(raan_deg, values, 180);
    out.max_abs_delta30  = i_shift_compare(raan_deg, values, 30);
end

function val = i_shift_compare(raan_deg, values, shift_deg)
    val = 0;
    for i = 1:numel(raan_deg)
        target = mod(raan_deg(i) + shift_deg, 360);
        j = find(abs(raan_deg - target) < 1e-9, 1, 'first');
        if ~isempty(j)
            val = max(val, abs(values(i) - values(j)));
        end
    end
end

function key_summary = i_build_key_summary(robust_stats_table)
    [v1, i1] = max(robust_stats_table.pass_ratio_mean);
    [v2, i2] = max(robust_stats_table.DG_mean_mean);
    [v3, i3] = max(robust_stats_table.DG_min_mean);

    metric1 = "best_mean_pass_ratio";
    F1 = robust_stats_table.F(i1);
    value1 = v1;

    metric2 = "best_mean_DG_mean";
    F2 = robust_stats_table.F(i2);
    value2 = v2;

    metric3 = "best_mean_DG_min";
    F3 = robust_stats_table.F(i3);
    value3 = v3;

    key_summary = table(metric1, F1, value1, metric2, F2, value2, metric3, F3, value3);
end
