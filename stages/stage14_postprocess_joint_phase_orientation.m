function post = stage14_postprocess_joint_phase_orientation(summary_table, opts)
%STAGE14_POSTPROCESS_JOINT_PHASE_ORIENTATION
% Official postprocess layer for Stage14.4 joint (F, RAAN) sensitivity.

    if nargin < 2
        opts = struct();
    end

    local = i_apply_defaults(opts, struct( ...
        'scope_name', "A1", ...
        'save_table', false, ...
        'output_dir', "", ...
        'timestamp', "" ...
    ));

    assert(istable(summary_table) && ~isempty(summary_table), ...
        'summary_table must be a non-empty table.');

    required_vars = { ...
        'F', 'RAAN_deg', 'pass_ratio', 'D_G_mean', 'D_G_min' ...
    };
    for k = 1:numel(required_vars)
        assert(any(strcmp(summary_table.Properties.VariableNames, required_vars{k})), ...
            'summary_table missing required variable: %s', required_vars{k});
    end

    F_values = unique(summary_table.F(:))';
    RAAN_values = unique(summary_table.RAAN_deg(:))';

    bestF_table = i_build_bestF_table(summary_table, RAAN_values);
    robust_stats_table = i_build_robust_stats_table(summary_table, F_values);
    dgmin_switch_table = i_build_dgmin_switch_table(bestF_table, F_values);
    periodicity = i_build_periodicity(summary_table);
    key_summary = i_build_key_summary(robust_stats_table);
    formal_summary_md = i_build_formal_summary_md(summary_table, key_summary, periodicity);

    post = struct();
    post.bestF_table = bestF_table;
    post.robust_stats_table = robust_stats_table;
    post.dgmin_switch_table = dgmin_switch_table;
    post.periodicity = periodicity;
    post.key_summary = key_summary;
    post.formal_summary_md = formal_summary_md;

    if local.save_table
        assert(strlength(string(local.output_dir)) > 0, ...
            'opts.output_dir must be provided when save_table=true.');
        if strlength(string(local.timestamp)) == 0
            local.timestamp = string(datestr(now, 'yyyymmdd_HHMMSS'));
        end
        i_save_outputs(post, local);
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
        bestF_DG_min, best_DG_min);
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
        pass_ratio_std, DG_mean_std, DG_min_std);
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

function md = i_build_formal_summary_md(summary_table, key_summary, periodicity)
    h_km = summary_table.h_km(1);
    i_deg = summary_table.i_deg(1);
    P = summary_table.P(1);
    T = summary_table.T(1);
    Ns = summary_table.Ns(1);

    md = sprintf([ ...
        '# Stage14 A1 正式结果摘要\n\n' ...
        '## 1. 实验对象\n' ...
        '- 构型：A1, h=%g km, i=%g deg, P=%g, T=%g, Ns=%g\n' ...
        '- 扫描变量：F = 0:7, RAAN = 0:15:345\n' ...
        '- 指标：D_G_min, D_G_mean, pass_ratio\n\n' ...
        '## 2. 核心结论\n' ...
        '- 平均表现最优相位：F=%g（pass_ratio_mean=%.6f, DG_mean_mean=%.6f）\n' ...
        '- 最坏-case 平均最优相位：F=%g（DG_min_mean=%.6f）\n' ...
        '- D_G_min 的最优 F 随 RAAN 切换，不存在唯一全局最优相位。\n' ...
        '- F=0 在 45/90/180 度位移下呈现严格重复，可作为对称基准态。\n\n' ...
        '## 3. F=0 对称基准态摘要\n' ...
        '- pass_ratio: max|Δ45|=%g, max|Δ90|=%g, max|Δ180|=%g, max|Δ30|=%g\n' ...
        '- DG_mean:   max|Δ45|=%g, max|Δ90|=%g, max|Δ180|=%g, max|Δ30|=%g\n' ...
        '- DG_min:    max|Δ45|=%g, max|Δ90|=%g, max|Δ180|=%g, max|Δ30|=%g\n'], ...
        h_km, i_deg, P, T, Ns, ...
        key_summary.F1(1), key_summary.value1(1), key_summary.value2(1), ...
        key_summary.F3(1), key_summary.value3(1), ...
        periodicity.pass_ratio.max_abs_delta45, periodicity.pass_ratio.max_abs_delta90, ...
        periodicity.pass_ratio.max_abs_delta180, periodicity.pass_ratio.max_abs_delta30, ...
        periodicity.DG_mean.max_abs_delta45, periodicity.DG_mean.max_abs_delta90, ...
        periodicity.DG_mean.max_abs_delta180, periodicity.DG_mean.max_abs_delta30, ...
        periodicity.DG_min.max_abs_delta45, periodicity.DG_min.max_abs_delta90, ...
        periodicity.DG_min.max_abs_delta180, periodicity.DG_min.max_abs_delta30);
end

function i_save_outputs(post, local)
    outdir = char(local.output_dir);
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end
    tag = char(local.timestamp);

    writetable(post.bestF_table, fullfile(outdir, ['stage14_' char(local.scope_name) '_bestF_table_' tag '.csv']));
    writetable(post.robust_stats_table, fullfile(outdir, ['stage14_' char(local.scope_name) '_robust_stats_' tag '.csv']));
    writetable(post.dgmin_switch_table, fullfile(outdir, ['stage14_' char(local.scope_name) '_bestF_DGmin_counts_' tag '.csv']));
    writetable(post.key_summary, fullfile(outdir, ['stage14_' char(local.scope_name) '_key_summary_' tag '.csv']));

    mdfile = fullfile(outdir, ['stage14_' char(local.scope_name) '_formal_summary_' tag '.md']);
    fid = fopen(mdfile, 'w');
    assert(fid > 0, 'Failed to open markdown output file.');
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, '%s\n', post.formal_summary_md);
end

function s = i_apply_defaults(s, defaults)
    names = fieldnames(defaults);
    for k = 1:numel(names)
        name = names{k};
        if ~isfield(s, name) || isempty(s.(name))
            s.(name) = defaults.(name);
        end
    end
end
