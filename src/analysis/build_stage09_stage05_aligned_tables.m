function S = build_stage09_stage05_aligned_tables(out9_4, cfg)
%BUILD_STAGE09_STAGE05_ALIGNED_TABLES Build Stage05-style diagnostics from Stage09.
%
% This helper extracts a fixed-h slice from the Stage09 full theta table and
% prepares Stage05-comparable diagnostic tables without touching Stage05 code.

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);

    if ~isstruct(out9_4) || ~isfield(out9_4, 'full_theta_table') || ~istable(out9_4.full_theta_table)
        error('build_stage09_stage05_aligned_tables requires out9_4.full_theta_table.');
    end

    Tfull = local_normalize_full_theta_table(out9_4.full_theta_table, cfg);
    h_slice_km = cfg.stage09.plot_h_slice_km;
    available_h_km = unique(Tfull.h_km(:)).';

    mask = abs(Tfull.h_km - h_slice_km) < 1e-9;
    if ~any(mask)
        error(['Requested Stage09 diagnostic h-slice %.6g km is unavailable. ' ...
            'Available h_km values: %s'], h_slice_km, mat2str(available_h_km));
    end

    slice_table = Tfull(mask, :);
    slice_table = sortrows(slice_table, ...
        {'i_deg', 'Ns', 'P', 'T', 'joint_margin', 'DG_rob'}, ...
        {'ascend', 'ascend', 'ascend', 'ascend', 'descend', 'descend'});

    slice_stage05_feasible_table = slice_table(slice_table.feasible_stage05_compat, :);
    slice_joint_feasible_table = slice_table(slice_table.joint_feasible, :);

    frontier_stage05_table = local_pick_best_by_i(slice_table, 'feasible_stage05_compat');
    frontier_joint_table = local_pick_best_by_i(slice_table, 'joint_feasible');

    S = struct();
    S.h_slice_km = h_slice_km;
    S.available_h_km = available_h_km;
    S.slice_table = slice_table;
    S.slice_stage05_feasible_table = slice_stage05_feasible_table;
    S.slice_joint_feasible_table = slice_joint_feasible_table;
    S.frontier_stage05_table = frontier_stage05_table;
    S.frontier_joint_table = frontier_joint_table;
    S.best_stage05_compat_by_i = frontier_stage05_table;
    S.best_joint_by_i = frontier_joint_table;
    S.best_stage05_compat_overall = local_pick_best_row(slice_stage05_feasible_table, slice_table);
    S.best_joint_overall = local_pick_best_row(slice_joint_feasible_table, slice_table);
    S.heatmap_minNs_iP_table = local_build_heatmap_minNs_table(slice_table);
    S.heatmap_bestDG_iP_table = local_build_heatmap_bestDG_table(slice_table);
    S.passratio_profile_table = local_build_passratio_profile_table(slice_table);
end


function Tfull = local_normalize_full_theta_table(Tfull, cfg)

    require_DG_min = cfg.stage09.require_DG_min;
    require_pass_ratio = cfg.stage09.require_pass_ratio;

    if ~ismember('DG_feasible', Tfull.Properties.VariableNames)
        Tfull.DG_feasible = isfinite(Tfull.DG_rob) & (Tfull.DG_rob >= require_DG_min);
    end
    if ~ismember('pass_feasible', Tfull.Properties.VariableNames)
        Tfull.pass_feasible = isfinite(Tfull.pass_ratio) & (Tfull.pass_ratio >= require_pass_ratio);
    end
    if ~ismember('feasible_stage05_compat', Tfull.Properties.VariableNames)
        Tfull.feasible_stage05_compat = Tfull.DG_feasible & Tfull.pass_feasible;
    end
    if ~ismember('joint_feasible', Tfull.Properties.VariableNames)
        error('full_theta_table must contain joint_feasible.');
    end
end


function Tbest = local_pick_best_by_i(slice_table, feasible_field)

    i_list = unique(slice_table.i_deg(:)).';
    rows = cell(numel(i_list), 1);
    nKeep = 0;

    for k = 1:numel(i_list)
        sub = slice_table(slice_table.i_deg == i_list(k) & slice_table.(feasible_field), :);
        if isempty(sub)
            continue;
        end

        sub = local_sort_candidate_rows(sub);
        nKeep = nKeep + 1;
        rows{nKeep} = sub(1, :);
    end

    if nKeep < 1
        Tbest = slice_table([], :);
    else
        Tbest = vertcat(rows{1:nKeep});
    end
end


function Tbest = local_pick_best_row(Tcand, template)

    if isempty(Tcand)
        Tbest = template([], :);
        return;
    end

    Tcand = local_sort_candidate_rows(Tcand);
    Tbest = Tcand(1, :);
end


function T = local_sort_candidate_rows(T)

    T = sortrows(T, ...
        {'Ns', 'joint_margin', 'DG_rob', 'pass_ratio', 'P', 'T'}, ...
        {'ascend', 'descend', 'descend', 'descend', 'ascend', 'ascend'});
end


function T = local_build_heatmap_minNs_table(slice_table)

    uIP = unique(slice_table(:, {'i_deg', 'P'}), 'rows');
    rows = cell(height(uIP), 1);

    for k = 1:height(uIP)
        sub_all = slice_table(slice_table.i_deg == uIP.i_deg(k) & slice_table.P == uIP.P(k), :);
        sub_feas = sub_all(sub_all.feasible_stage05_compat, :);

        row = struct();
        row.i_deg = uIP.i_deg(k);
        row.P = uIP.P(k);
        row.n_total = height(sub_all);
        row.n_stage05_compat = height(sub_feas);
        row.has_feasible = ~isempty(sub_feas);

        if row.has_feasible
            sub_feas = local_sort_candidate_rows(sub_feas);
            best = sub_feas(1, :);
            row.min_feasible_Ns = best.Ns;
            row.T_at_minNs = best.T;
            row.DG_rob_at_minNs = best.DG_rob;
            row.pass_ratio_at_minNs = best.pass_ratio;
            row.joint_margin_at_minNs = best.joint_margin;
        else
            row.min_feasible_Ns = NaN;
            row.T_at_minNs = NaN;
            row.DG_rob_at_minNs = NaN;
            row.pass_ratio_at_minNs = NaN;
            row.joint_margin_at_minNs = NaN;
        end

        rows{k} = row;
    end

    T = struct2table(vertcat(rows{:}));
    T = sortrows(T, {'P', 'i_deg'}, {'ascend', 'ascend'});
end


function T = local_build_heatmap_bestDG_table(slice_table)

    uIP = unique(slice_table(:, {'i_deg', 'P'}), 'rows');
    rows = cell(height(uIP), 1);

    for k = 1:height(uIP)
        sub_all = slice_table(slice_table.i_deg == uIP.i_deg(k) & slice_table.P == uIP.P(k), :);
        sub_feas = sub_all(sub_all.feasible_stage05_compat, :);

        row = struct();
        row.i_deg = uIP.i_deg(k);
        row.P = uIP.P(k);
        row.n_total = height(sub_all);
        row.n_stage05_compat = height(sub_feas);
        row.has_feasible = ~isempty(sub_feas);

        if row.has_feasible
            sub_feas = sortrows(sub_feas, ...
                {'DG_rob', 'pass_ratio', 'joint_margin', 'Ns', 'T'}, ...
                {'descend', 'descend', 'descend', 'ascend', 'ascend'});
            best = sub_feas(1, :);
            row.best_DG_rob = best.DG_rob;
            row.best_pass_ratio = best.pass_ratio;
            row.best_joint_margin = best.joint_margin;
            row.best_Ns = best.Ns;
            row.best_T = best.T;
        else
            row.best_DG_rob = NaN;
            row.best_pass_ratio = NaN;
            row.best_joint_margin = NaN;
            row.best_Ns = NaN;
            row.best_T = NaN;
        end

        rows{k} = row;
    end

    T = struct2table(vertcat(rows{:}));
    T = sortrows(T, {'P', 'i_deg'}, {'ascend', 'ascend'});
end


function T = local_build_passratio_profile_table(slice_table)

    uIN = unique(slice_table(:, {'i_deg', 'Ns'}), 'rows');
    rows = cell(height(uIN), 1);

    for k = 1:height(uIN)
        sub = slice_table(slice_table.i_deg == uIN.i_deg(k) & slice_table.Ns == uIN.Ns(k), :);

        row = struct();
        row.i_deg = uIN.i_deg(k);
        row.Ns = uIN.Ns(k);
        row.n_design = height(sub);
        row.max_pass_ratio = local_max_or_nan(sub.pass_ratio);
        row.max_DG_rob = local_max_or_nan(sub.DG_rob);
        row.max_joint_margin = local_max_or_nan(sub.joint_margin);
        row.has_stage05_compat = any(sub.feasible_stage05_compat);
        row.has_joint_feasible = any(sub.joint_feasible);
        rows{k} = row;
    end

    T = struct2table(vertcat(rows{:}));
    T = sortrows(T, {'i_deg', 'Ns'}, {'ascend', 'ascend'});
end


function val = local_max_or_nan(x)

    x = x(isfinite(x));
    if isempty(x)
        val = NaN;
    else
        val = max(x);
    end
end
