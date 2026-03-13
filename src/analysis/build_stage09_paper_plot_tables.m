function S = build_stage09_paper_plot_tables(out9_4, out9_5)
%BUILD_STAGE09_PAPER_PLOT_TABLES
% Build aggregated tables for Stage09 paper-quality figures.
%
% Outputs:
%   S.hi_minNs_table
%       For each (h,i), the minimum feasible Ns among all P,T
%   S.pt_minNs_table
%       For each (P,T), whether feasible points exist and the fixed Ns=P*T
%   S.theta_min_table
%       Minimum-size feasible set
%   S.fail_hi_refPT_table
%       Fail partition in h-i plane at representative PT pair

    Tfull = out9_4.full_theta_table;
    Tfeas = out9_4.feasible_theta_table;
    Tmin  = out9_5.theta_min_table_sorted;

    % ------------------------------------------------------------
    % (1) h-i -> minimum feasible Ns
    % ------------------------------------------------------------
    [ui, ~, gi] = unique(Tfull(:, {'h_km','i_deg'}), 'rows');
    hi_rows = cell(height(ui), 1);

    for k = 1:height(ui)
        mask = (Tfull.h_km == ui.h_km(k)) & (Tfull.i_deg == ui.i_deg(k));
        Tk = Tfull(mask, :);

        if any(Tk.joint_feasible)
            Ns_min_feasible = min(Tk.Ns(Tk.joint_feasible));
            has_feasible = true;
        else
            Ns_min_feasible = NaN;
            has_feasible = false;
        end

        row = struct();
        row.h_km = ui.h_km(k);
        row.i_deg = ui.i_deg(k);
        row.has_feasible = has_feasible;
        row.Ns_min_feasible = Ns_min_feasible;
        hi_rows{k} = row;
    end
    hi_minNs_table = struct2table(vertcat(hi_rows{:}));

    % ------------------------------------------------------------
    % (2) P-T -> feasible existence
    % ------------------------------------------------------------
    [uPT, ~, ~] = unique(Tfull(:, {'P','T'}), 'rows');
    pt_rows = cell(height(uPT), 1);

    for k = 1:height(uPT)
        mask = (Tfull.P == uPT.P(k)) & (Tfull.T == uPT.T(k));
        Tk = Tfull(mask, :);

        row = struct();
        row.P = uPT.P(k);
        row.T = uPT.T(k);
        row.Ns = uPT.P(k) * uPT.T(k);
        row.has_feasible = any(Tk.joint_feasible);
        if row.has_feasible
            row.joint_margin_best = max(Tk.joint_margin(Tk.joint_feasible));
        else
            row.joint_margin_best = NaN;
        end
        pt_rows{k} = row;
    end
    pt_minNs_table = struct2table(vertcat(pt_rows{:}));

    % ------------------------------------------------------------
    % (3) representative PT pair at Nmin
    % ------------------------------------------------------------
    if isempty(Tmin)
        PT_ref = table();
        fail_hi_refPT_table = table();
    else
        PT_ref = unique(Tmin(:, {'P','T'}), 'rows');
        PT_ref = sortrows(PT_ref, {'P','T'}, {'ascend','ascend'});
        P_ref = PT_ref.P(1);
        T_ref = PT_ref.T(1);

        Tref = Tfull(Tfull.P == P_ref & Tfull.T == T_ref, :);
        fail_hi_refPT_table = Tref(:, {'h_km','i_deg','dominant_fail_tag','joint_feasible','joint_margin','Ns'});
        fail_hi_refPT_table = sortrows(fail_hi_refPT_table, ...
            {'h_km','i_deg'}, {'ascend','ascend'});
    end

    S = struct();
    S.hi_minNs_table = hi_minNs_table;
    S.pt_minNs_table = pt_minNs_table;
    S.theta_min_table = Tmin;
    S.PT_ref = PT_ref;
    S.fail_hi_refPT_table = fail_hi_refPT_table;
end