function gates = stage09_dump_final_gate_tables(out, topN)
%STAGE09_DUMP_FINAL_GATE_TABLES
% Dump final DG / DA / DT / joint gate tables from Stage09 full_theta_table.
%
% Usage:
%   gates = stage09_dump_final_gate_tables(out)
%   gates = stage09_dump_final_gate_tables(out, 20)

    if nargin < 2 || isempty(topN)
        topN = 20;
    end

    if ~isfield(out, 's4') || ~isfield(out.s4, 'full_theta_table')
        error('stage09_dump_final_gate_tables requires out.s4.full_theta_table.');
    end

    T = out.s4.full_theta_table;
    cfg = out.s4.cfg;

    reqDG = cfg.stage09.require_DG_min;
    reqDA = cfg.stage09.require_DA_min;
    reqDT = cfg.stage09.require_DT_min;
    reqPR = cfg.stage09.require_pass_ratio;

    run_tag = char(string(cfg.stage09.run_tag));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    tables_dir = cfg.paths.tables;
    if ~exist(tables_dir, 'dir')
        mkdir(tables_dir);
    end

    G = T(:, {'h_km','i_deg','P','T','F','Ns','DG_rob','pass_ratio','joint_feasible','dominant_fail_tag'});
    G.DG_margin = G.DG_rob - reqDG;
    G.pass_DG = isfinite(G.DG_rob) & (G.DG_rob >= reqDG);
    G.pass_PR = isfinite(G.pass_ratio) & (G.pass_ratio >= reqPR);
    G = movevars(G, {'DG_margin','pass_DG','pass_PR'}, 'After', 'DG_rob');

    A = T(:, {'h_km','i_deg','P','T','F','Ns','DA_rob','DG_rob','DT_rob','pass_ratio','joint_feasible','dominant_fail_tag'});
    A.DA_margin = A.DA_rob - reqDA;
    A.pass_DA = isfinite(A.DA_rob) & (A.DA_rob >= reqDA);
    A = movevars(A, {'DA_margin','pass_DA'}, 'After', 'DA_rob');

    D = T(:, {'h_km','i_deg','P','T','F','Ns','DT_rob','DG_rob','DA_rob','pass_ratio','joint_feasible','dominant_fail_tag'});
    D.DT_margin = D.DT_rob - reqDT;
    D.pass_DT = isfinite(D.DT_rob) & (D.DT_rob >= reqDT);
    D = movevars(D, {'DT_margin','pass_DT'}, 'After', 'DT_rob');

    J = T(:, {'h_km','i_deg','P','T','F','Ns','DG_rob','DA_rob','DT_rob','pass_ratio','joint_margin','joint_feasible','dominant_fail_tag'});
    J.pass_DG = isfinite(J.DG_rob) & (J.DG_rob >= reqDG);
    J.pass_DA = isfinite(J.DA_rob) & (J.DA_rob >= reqDA);
    J.pass_DT = isfinite(J.DT_rob) & (J.DT_rob >= reqDT);
    J.pass_PR = isfinite(J.pass_ratio) & (J.pass_ratio >= reqPR);
    J = movevars(J, {'pass_DG','pass_DA','pass_DT','pass_PR'}, 'After', 'pass_ratio');

    summary = table( ...
        height(T), ...
        sum(J.pass_DG), ...
        sum(J.pass_DA), ...
        sum(J.pass_DT), ...
        sum(J.pass_PR), ...
        sum(J.joint_feasible), ...
        reqDG, reqDA, reqDT, reqPR, ...
        'VariableNames', { ...
            'n_theta_total', ...
            'n_pass_DG', ...
            'n_pass_DA', ...
            'n_pass_DT', ...
            'n_pass_PR', ...
            'n_joint_feasible', ...
            'require_DG_min', ...
            'require_DA_min', ...
            'require_DT_min', ...
            'require_pass_ratio'});

    dg_csv = fullfile(tables_dir, sprintf('stage09_final_gate_DG_table_%s_%s.csv', run_tag, timestamp));
    da_csv = fullfile(tables_dir, sprintf('stage09_final_gate_DA_table_%s_%s.csv', run_tag, timestamp));
    dt_csv = fullfile(tables_dir, sprintf('stage09_final_gate_DT_table_%s_%s.csv', run_tag, timestamp));
    joint_csv = fullfile(tables_dir, sprintf('stage09_final_gate_joint_table_%s_%s.csv', run_tag, timestamp));
    summary_csv = fullfile(tables_dir, sprintf('stage09_final_gate_summary_%s_%s.csv', run_tag, timestamp));

    writetable(G, dg_csv);
    writetable(A, da_csv);
    writetable(D, dt_csv);
    writetable(J, joint_csv);
    writetable(summary, summary_csv);

    fprintf('\n');
    fprintf('================ Final Gate Tables ================\n');
    fprintf('run_tag            : %s\n', run_tag);
    fprintf('n_theta_total      : %d\n', height(T));
    fprintf('n_pass_DG          : %d\n', sum(J.pass_DG));
    fprintf('n_pass_DA          : %d\n', sum(J.pass_DA));
    fprintf('n_pass_DT          : %d\n', sum(J.pass_DT));
    fprintf('n_pass_PR          : %d\n', sum(J.pass_PR));
    fprintf('n_joint_feasible   : %d\n', sum(J.joint_feasible));
    fprintf('DG table           : %s\n', dg_csv);
    fprintf('DA table           : %s\n', da_csv);
    fprintf('DT table           : %s\n', dt_csv);
    fprintf('joint table        : %s\n', joint_csv);
    fprintf('summary table      : %s\n', summary_csv);
    fprintf('===================================================\n');
    fprintf('\n');

    fprintf('---- DG closest to threshold ----\n');
    Gp = sortrows(G, {'DG_margin','Ns'}, {'ascend','ascend'});
    disp(Gp(1:min(topN,height(Gp)), :));

    fprintf('\n---- DA closest to threshold ----\n');
    Ap = sortrows(A, {'DA_margin','Ns'}, {'ascend','ascend'});
    disp(Ap(1:min(topN,height(Ap)), :));

    fprintf('\n---- DT closest to threshold ----\n');
    Dp = sortrows(D, {'DT_margin','Ns'}, {'ascend','ascend'});
    disp(Dp(1:min(topN,height(Dp)), :));

    fprintf('\n---- joint-feasible rows ----\n');
    Jok = sortrows(J(J.joint_feasible,:), {'Ns','i_deg','P','T'}, {'ascend','ascend','ascend','ascend'});
    disp(Jok(1:min(topN,height(Jok)), :));

    fprintf('\n---- non-feasible rows closest to joint boundary ----\n');
    Jbad = sortrows(J(~J.joint_feasible,:), {'joint_margin','Ns'}, {'descend','ascend'});
    disp(Jbad(1:min(topN,height(Jbad)), :));

    gates = struct();
    gates.DG_table = G;
    gates.DA_table = A;
    gates.DT_table = D;
    gates.joint_table = J;
    gates.summary_table = summary;
    gates.files = struct();
    gates.files.dg_csv = dg_csv;
    gates.files.da_csv = da_csv;
    gates.files.dt_csv = dt_csv;
    gates.files.joint_csv = joint_csv;
    gates.files.summary_csv = summary_csv;
end
