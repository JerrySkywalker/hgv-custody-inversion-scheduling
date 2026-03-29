function out = summarize_stage09_grid(result_bank, cfg_or_stage09)
%SUMMARIZE_STAGE09_GRID Summarize Stage09.4 full-domain scan results.
%
% Input
%   result_bank     : struct array from evaluate_single_layer_walker_stage09
%   cfg_or_stage09  : cfg or cfg.stage09-like struct
%
% Output fields
%   out.full_theta_table
%   out.stage05_compat_theta_table
%   out.feasible_theta_table
%   out.infeasible_theta_table
%   out.fail_partition_table
%   out.summary_table

    if nargin < 2
        error('summarize_stage09_grid requires result_bank and cfg_or_stage09.');
    end

    s9 = local_pick_stage09(cfg_or_stage09);
    if isempty(result_bank)
        error('result_bank is empty.');
    end

    require_DG_min = local_get_numeric_field(s9, 'require_DG_min', 1.0);
    require_pass_ratio = local_get_numeric_field(s9, 'require_pass_ratio', 1.0);
    sort_full_table = local_get_logical_field(s9, 'sort_full_table', true);

    n = numel(result_bank);
    rows = cell(n, 1);

    for k = 1:n
        r = result_bank(k);

        row = struct();
        row.h_km = r.walker.h_km;
        row.i_deg = r.walker.i_deg;
        row.P = r.walker.P;
        row.T = r.walker.T;
        row.F = r.walker.F;
        row.Ns = r.walker.P * r.walker.T;

        row.DG_rob = r.DG_rob;
        row.DA_rob = r.DA_rob;
        row.DT_bar_rob = r.DT_bar_rob;
        row.DT_rob = r.DT_rob;
        row.joint_margin = r.joint_margin;
        row.pass_ratio = r.pass_ratio;

        row.DG_feasible = isfinite(r.DG_rob) && (r.DG_rob >= require_DG_min);
        row.pass_feasible = isfinite(r.pass_ratio) && (r.pass_ratio >= require_pass_ratio);
        row.feasible_stage05_compat = row.DG_feasible && row.pass_feasible;
        row.joint_feasible = logical(r.feasible_flag);

        row.dominant_fail_tag = string(r.dominant_fail_tag);
        row.worst_case_id_DG = string(r.worst_case_id_DG);
        row.worst_case_id_DA = string(r.worst_case_id_DA);
        row.worst_case_id_DT = string(r.worst_case_id_DT);
        row.rank_score = r.rank_score;
        row.n_case_total = r.n_case_total;
        row.n_case_evaluated = r.n_case_evaluated;
        row.failed_early = logical(r.failed_early);

        rows{k} = row;
    end

    full_theta_table = struct2table(vertcat(rows{:}));

    if sort_full_table
        full_theta_table = sortrows(full_theta_table, ...
            {'joint_feasible', 'feasible_stage05_compat', 'Ns', 'joint_margin', 'DG_rob', 'h_km', 'i_deg', 'P', 'T'}, ...
            {'descend', 'descend', 'ascend', 'descend', 'descend', 'ascend', 'ascend', 'ascend', 'ascend'});
    end

    stage05_compat_mask = full_theta_table.feasible_stage05_compat;
    feasible_mask = full_theta_table.joint_feasible;

    stage05_compat_theta_table = full_theta_table(stage05_compat_mask, :);
    feasible_theta_table = full_theta_table(feasible_mask, :);
    infeasible_theta_table = full_theta_table(~feasible_mask, :);

    fail_tags = full_theta_table.dominant_fail_tag;
    if isstring(fail_tags)
        [uTags, ~, ic] = unique(fail_tags);
        counts = accumarray(ic, 1);
        fail_partition_table = table(uTags, counts, ...
            'VariableNames', {'dominant_fail_tag', 'count'});
        fail_partition_table = sortrows(fail_partition_table, 'count', 'descend');
    else
        fail_partition_table = table();
    end

    summary_table = table( ...
        height(full_theta_table), ...
        height(stage05_compat_theta_table), ...
        height(feasible_theta_table), ...
        height(infeasible_theta_table), ...
        min(full_theta_table.Ns), ...
        local_min_or_inf(stage05_compat_theta_table), ...
        local_min_or_inf(feasible_theta_table), ...
        'VariableNames', { ...
            'n_theta_total', ...
            'n_theta_stage05_compat', ...
            'n_theta_feasible', ...
            'n_theta_infeasible', ...
            'Ns_min_scanned', ...
            'Ns_min_stage05_compat', ...
            'Ns_min_feasible'});

    out = struct();
    out.full_theta_table = full_theta_table;
    out.stage05_compat_theta_table = stage05_compat_theta_table;
    out.feasible_theta_table = feasible_theta_table;
    out.infeasible_theta_table = infeasible_theta_table;
    out.fail_partition_table = fail_partition_table;
    out.summary_table = summary_table;
end


function s9 = local_pick_stage09(cfg_or_stage09)

    if isstruct(cfg_or_stage09) && isfield(cfg_or_stage09, 'stage09')
        s9 = cfg_or_stage09.stage09;
    else
        s9 = cfg_or_stage09;
    end
end


function val = local_min_or_inf(T)

    if isempty(T) || height(T) < 1
        val = inf;
    else
        val = min(T.Ns);
    end
end


function val = local_get_numeric_field(S, field_name, default_value)

    val = default_value;
    if isstruct(S) && isfield(S, field_name) && ~isempty(S.(field_name))
        val = S.(field_name);
    end
end


function val = local_get_logical_field(S, field_name, default_value)

    val = default_value;
    if isstruct(S) && isfield(S, field_name) && ~isempty(S.(field_name))
        val = logical(S.(field_name));
    end
end
