function S = build_stage09_paper_plot_tables(out9_4, out9_5, cfg)
%BUILD_STAGE09_PAPER_PLOT_TABLES Build aggregated tables for Stage09 figures.
%
% Outputs:
%   S.hi_minNs_table
%   S.pt_minNs_table
%   S.theta_min_table
%   S.PT_ref_table
%   S.fail_hi_refPT_table

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);

    Tfull = out9_4.full_theta_table;
    if isfield(out9_4, 'feasible_theta_table') && istable(out9_4.feasible_theta_table)
        Tfeas = out9_4.feasible_theta_table;
    else
        Tfeas = Tfull(Tfull.joint_feasible, :);
    end

    if isfield(out9_5, 'theta_min_table_sorted') && istable(out9_5.theta_min_table_sorted)
        Tmin = out9_5.theta_min_table_sorted;
    else
        Tmin = table();
    end

    % ------------------------------------------------------------
    % (1) h-i -> minimum feasible Ns
    % ------------------------------------------------------------
    uHI = unique(Tfull(:, {'h_km', 'i_deg'}), 'rows');
    hi_rows = cell(height(uHI), 1);

    for k = 1:height(uHI)
        Tk = Tfull(Tfull.h_km == uHI.h_km(k) & Tfull.i_deg == uHI.i_deg(k), :);
        Tkj = Tk(Tk.joint_feasible, :);

        row = struct();
        row.h_km = uHI.h_km(k);
        row.i_deg = uHI.i_deg(k);
        row.has_feasible = ~isempty(Tkj);

        if row.has_feasible
            Tkj = local_sort_joint_candidates(Tkj);
            best = Tkj(1, :);
            row.Ns_min_feasible = best.Ns;
            row.P_at_minNs = best.P;
            row.T_at_minNs = best.T;
            row.joint_margin_at_minNs = best.joint_margin;
            row.DG_at_minNs = best.DG_rob;
            row.pass_ratio_at_minNs = best.pass_ratio;
        else
            row.Ns_min_feasible = NaN;
            row.P_at_minNs = NaN;
            row.T_at_minNs = NaN;
            row.joint_margin_at_minNs = NaN;
            row.DG_at_minNs = NaN;
            row.pass_ratio_at_minNs = NaN;
        end

        hi_rows{k} = row;
    end
    hi_minNs_table = struct2table(vertcat(hi_rows{:}));
    hi_minNs_table = sortrows(hi_minNs_table, {'h_km', 'i_deg'}, {'ascend', 'ascend'});

    % ------------------------------------------------------------
    % (2) P-T -> feasible existence and h-i coverage stats
    % ------------------------------------------------------------
    uPT = unique(Tfull(:, {'P', 'T'}), 'rows');
    pt_rows = cell(height(uPT), 1);

    for k = 1:height(uPT)
        Tk = Tfull(Tfull.P == uPT.P(k) & Tfull.T == uPT.T(k), :);

        row = struct();
        row.P = uPT.P(k);
        row.T = uPT.T(k);
        row.Ns = uPT.P(k) * uPT.T(k);
        row.has_feasible = any(Tk.joint_feasible);
        row.count_feasible_hi = sum(Tk.joint_feasible);
        row.count_total_hi = height(Tk);

        if row.count_total_hi > 0
            row.feasible_ratio_hi = row.count_feasible_hi / row.count_total_hi;
        else
            row.feasible_ratio_hi = NaN;
        end

        row.joint_margin_best = local_max_or_nan(Tk.joint_margin);
        row.joint_margin_median = local_median_or_nan(Tk.joint_margin);
        row.DG_best = local_max_or_nan(Tk.DG_rob);
        row.pass_ratio_best = local_max_or_nan(Tk.pass_ratio);
        pt_rows{k} = row;
    end
    pt_minNs_table = struct2table(vertcat(pt_rows{:}));
    pt_minNs_table = sortrows(pt_minNs_table, {'Ns', 'P', 'T'}, {'ascend', 'ascend', 'ascend'});

    % ------------------------------------------------------------
    % (3) representative PT pair(s) at Nmin
    % ------------------------------------------------------------
    PT_ref_table = local_resolve_refPT_table(Tmin, Tfull, cfg);

    if isempty(PT_ref_table)
        fail_hi_refPT_table = table();
    else
        empty_ref_template = Tfull([], {'h_km', 'i_deg', 'P', 'T', 'dominant_fail_tag', 'joint_feasible', 'joint_margin', 'DG_rob', 'pass_ratio', 'Ns'});
        ref_rows = cell(height(PT_ref_table), 1);
        for k = 1:height(PT_ref_table)
            Tref = Tfull(Tfull.P == PT_ref_table.P(k) & Tfull.T == PT_ref_table.T(k), :);
            if isempty(Tref)
                ref_rows{k} = empty_ref_template;
                continue;
            end

            Tref = Tref(:, {'h_km', 'i_deg', 'P', 'T', 'dominant_fail_tag', 'joint_feasible', 'joint_margin', 'DG_rob', 'pass_ratio', 'Ns'});
            ref_rows{k} = sortrows(Tref, {'h_km', 'i_deg'}, {'ascend', 'ascend'});
        end

        fail_hi_refPT_table = vertcat(ref_rows{:});
        fail_hi_refPT_table = sortrows(fail_hi_refPT_table, {'P', 'T', 'h_km', 'i_deg'}, {'ascend', 'ascend', 'ascend', 'ascend'});
    end

    S = struct();
    S.hi_minNs_table = hi_minNs_table;
    S.pt_minNs_table = pt_minNs_table;
    S.theta_min_table = Tmin;
    S.PT_ref = PT_ref_table;
    S.PT_ref_table = PT_ref_table;
    S.fail_hi_refPT_table = fail_hi_refPT_table;
    S.refPT_mode = string(cfg.stage09.refPT_mode);
    S.full_theta_table = Tfull;
    S.feasible_theta_table = Tfeas;
end


function T = local_sort_joint_candidates(T)

    T = sortrows(T, ...
        {'Ns', 'joint_margin', 'DG_rob', 'pass_ratio', 'P', 'T'}, ...
        {'ascend', 'descend', 'descend', 'descend', 'ascend', 'ascend'});
end


function PT_ref_table = local_resolve_refPT_table(Tmin, Tfull, cfg)

    mode = lower(string(cfg.stage09.refPT_mode));

    switch mode
        case "first_theta_min"
            if isempty(Tmin)
                PT_ref_table = table();
            else
                PT_ref_table = unique(Tmin(:, {'P', 'T'}), 'rows');
                PT_ref_table = sortrows(PT_ref_table, {'P', 'T'}, {'ascend', 'ascend'});
                PT_ref_table = PT_ref_table(1, :);
            end

        case "all_theta_min_pairs"
            if isempty(Tmin)
                PT_ref_table = table();
            else
                PT_ref_table = unique(Tmin(:, {'P', 'T'}), 'rows');
                PT_ref_table = sortrows(PT_ref_table, {'P', 'T'}, {'ascend', 'ascend'});
            end

        case "user_fixed"
            [P_ref, T_ref] = local_extract_user_fixed_refPT(cfg);
            PT_ref_table = table(P_ref, T_ref, 'VariableNames', {'P', 'T'});

            exists_mask = any(Tfull.P == P_ref & Tfull.T == T_ref);
            if ~exists_mask
                error('User-fixed ref PT pair (P=%g, T=%g) does not exist in full_theta_table.', P_ref, T_ref);
            end

        otherwise
            error('Unsupported cfg.stage09.refPT_mode: %s', string(cfg.stage09.refPT_mode));
    end
end


function [P_ref, T_ref] = local_extract_user_fixed_refPT(cfg)

    P_ref = NaN;
    T_ref = NaN;

    if isfield(cfg.stage09, 'refPT_user') && isstruct(cfg.stage09.refPT_user)
        if isfield(cfg.stage09.refPT_user, 'P')
            P_ref = cfg.stage09.refPT_user.P;
        end
        if isfield(cfg.stage09.refPT_user, 'T')
            T_ref = cfg.stage09.refPT_user.T;
        end
    elseif isfield(cfg.stage09, 'refPT_user_pair') && numel(cfg.stage09.refPT_user_pair) >= 2
        P_ref = cfg.stage09.refPT_user_pair(1);
        T_ref = cfg.stage09.refPT_user_pair(2);
    elseif isfield(cfg.stage09, 'refPT_P') && isfield(cfg.stage09, 'refPT_T')
        P_ref = cfg.stage09.refPT_P;
        T_ref = cfg.stage09.refPT_T;
    end

    if ~isscalar(P_ref) || ~isscalar(T_ref) || ~isfinite(P_ref) || ~isfinite(T_ref)
        error(['cfg.stage09.refPT_mode=user_fixed requires a valid PT pair in one of: ' ...
            'cfg.stage09.refPT_user.(P,T), cfg.stage09.refPT_user_pair, or cfg.stage09.refPT_P/refPT_T.']);
    end
end


function val = local_max_or_nan(x)

    x = x(isfinite(x));
    if isempty(x)
        val = NaN;
    else
        val = max(x);
    end
end


function val = local_median_or_nan(x)

    x = x(isfinite(x));
    if isempty(x)
        val = NaN;
    else
        val = median(x);
    end
end
