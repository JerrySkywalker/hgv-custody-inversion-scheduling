function diag = stage09_dump_metric_diagnosis(out, mode_tag, topN)
%STAGE09_DUMP_METRIC_DIAGNOSIS
% Build diagnosis tables from Stage09 full_theta_table and print summaries.
%
% Inputs
%   out      : output struct from manual_smoke_stage09_stage05_aligned_fullscan
%   mode_tag : e.g. 'DA_only', 'DT_only', 'joint_metrics'
%   topN     : number of rows to print in CLI
%
% Main outputs
%   diag.diag_table
%   diag.summary_table
%   diag.files.*

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'diagnosis';
    end
    if nargin < 3 || isempty(topN)
        topN = 12;
    end

    if ~isfield(out, 's4') || ~isfield(out.s4, 'full_theta_table')
        error('stage09_dump_metric_diagnosis requires out.s4.full_theta_table.');
    end

    cfg = out.s4.cfg;
    T = out.s4.full_theta_table;
    run_tag = char(string(cfg.stage09.run_tag));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    tables_dir = cfg.paths.tables;
    if ~exist(tables_dir, 'dir')
        mkdir(tables_dir);
    end

    reqDG = cfg.stage09.require_DG_min;
    reqDA = cfg.stage09.require_DA_min;
    reqDT = cfg.stage09.require_DT_min;
    reqPR = cfg.stage09.require_pass_ratio;

    Tdiag = T;
    Tdiag.pass_DG = isfinite(Tdiag.DG_rob) & (Tdiag.DG_rob >= reqDG);
    Tdiag.pass_DA = isfinite(Tdiag.DA_rob) & (Tdiag.DA_rob >= reqDA);
    Tdiag.pass_DT = isfinite(Tdiag.DT_rob) & (Tdiag.DT_rob >= reqDT);
    Tdiag.pass_PR = isfinite(Tdiag.pass_ratio) & (Tdiag.pass_ratio >= reqPR);

    Tdiag.feasible_DG_pass = Tdiag.pass_DG & Tdiag.pass_PR;
    Tdiag.feasible_DG_DA_pass = Tdiag.pass_DG & Tdiag.pass_DA & Tdiag.pass_PR;
    Tdiag.feasible_DG_DT_pass = Tdiag.pass_DG & Tdiag.pass_DT & Tdiag.pass_PR;
    Tdiag.feasible_joint_recomputed = Tdiag.pass_DG & Tdiag.pass_DA & Tdiag.pass_DT & Tdiag.pass_PR;

    Tdiag.killed_by_DA = Tdiag.feasible_DG_pass & ~Tdiag.pass_DA;
    Tdiag.killed_by_DT = Tdiag.feasible_DG_pass & ~Tdiag.pass_DT;
    Tdiag.killed_in_joint = Tdiag.feasible_DG_pass & ~Tdiag.joint_feasible;

    Tdiag.DG_margin_to_1 = Tdiag.DG_rob - reqDG;
    Tdiag.DA_margin_to_1 = Tdiag.DA_rob - reqDA;
    Tdiag.DT_margin_to_1 = Tdiag.DT_rob - reqDT;
    Tdiag.PR_margin_to_1 = Tdiag.pass_ratio - reqPR;

    fail_tags = string(Tdiag.dominant_fail_tag);
    [uTags, ~, ic] = unique(fail_tags);
    counts = accumarray(ic, 1);
    fail_summary = table(uTags, counts, 'VariableNames', {'dominant_fail_tag','count'});
    fail_summary = sortrows(fail_summary, 'count', 'descend');

    summary_table = table( ...
        height(Tdiag), ...
        sum(Tdiag.feasible_stage05_compat), ...
        sum(Tdiag.joint_feasible), ...
        sum(Tdiag.pass_DG), ...
        sum(Tdiag.pass_DA), ...
        sum(Tdiag.pass_DT), ...
        sum(Tdiag.pass_PR), ...
        sum(Tdiag.killed_by_DA), ...
        sum(Tdiag.killed_by_DT), ...
        sum(Tdiag.killed_in_joint), ...
        'VariableNames', { ...
            'n_theta_total', ...
            'n_stage05_compat', ...
            'n_joint_feasible', ...
            'n_pass_DG', ...
            'n_pass_DA', ...
            'n_pass_DT', ...
            'n_pass_PR', ...
            'n_killed_by_DA', ...
            'n_killed_by_DT', ...
            'n_killed_in_joint'});

    % ---------------------------------------------------------
    % Export tables
    % ---------------------------------------------------------
    diag_csv = fullfile(tables_dir, sprintf('stage09_metric_diagnosis_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    summary_csv = fullfile(tables_dir, sprintf('stage09_metric_diagnosis_summary_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    fail_csv = fullfile(tables_dir, sprintf('stage09_metric_diagnosis_failtags_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    killed_da_csv = fullfile(tables_dir, sprintf('stage09_DA_delta_from_DG_only_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    killed_dt_csv = fullfile(tables_dir, sprintf('stage09_DT_delta_from_DG_only_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    killed_joint_csv = fullfile(tables_dir, sprintf('stage09_joint_delta_from_DG_only_%s_%s_%s.csv', run_tag, mode_tag, timestamp));

    writetable(Tdiag, diag_csv);
    writetable(summary_table, summary_csv);
    writetable(fail_summary, fail_csv);
    writetable(Tdiag(Tdiag.killed_by_DA, :), killed_da_csv);
    writetable(Tdiag(Tdiag.killed_by_DT, :), killed_dt_csv);
    writetable(Tdiag(Tdiag.killed_in_joint, :), killed_joint_csv);

    % ---------------------------------------------------------
    % CLI summary
    % ---------------------------------------------------------
    fprintf('\n');
    fprintf('================ Stage09 Metric Diagnosis ================\n');
    fprintf('mode_tag               : %s\n', mode_tag);
    fprintf('run_tag                : %s\n', run_tag);
    fprintf('n_theta_total          : %d\n', height(Tdiag));
    fprintf('n_stage05_compat       : %d\n', sum(Tdiag.feasible_stage05_compat));
    fprintf('n_joint_feasible       : %d\n', sum(Tdiag.joint_feasible));
    fprintf('n_pass_DG              : %d\n', sum(Tdiag.pass_DG));
    fprintf('n_pass_DA              : %d\n', sum(Tdiag.pass_DA));
    fprintf('n_pass_DT              : %d\n', sum(Tdiag.pass_DT));
    fprintf('n_pass_PR              : %d\n', sum(Tdiag.pass_PR));
    fprintf('n_killed_by_DA         : %d\n', sum(Tdiag.killed_by_DA));
    fprintf('n_killed_by_DT         : %d\n', sum(Tdiag.killed_by_DT));
    fprintf('n_killed_in_joint      : %d\n', sum(Tdiag.killed_in_joint));
    fprintf('diag csv               : %s\n', diag_csv);
    fprintf('summary csv            : %s\n', summary_csv);
    fprintf('fail-tag csv           : %s\n', fail_csv);
    fprintf('==========================================================\n');
    fprintf('\n');

    disp('---- dominant fail tags ----');
    disp(fail_summary);

    cols = {'h_km','i_deg','P','T','Ns','DG_rob','DA_rob','DT_rob','pass_ratio','joint_margin','feasible_stage05_compat','joint_feasible','dominant_fail_tag'};

    fprintf('\n---- closest DA rows to threshold ----\n');
    Tda = sortrows(Tdiag(abs(Tdiag.DA_margin_to_1) < inf, :), {'DA_margin_to_1','Ns'}, {'ascend','ascend'});
    if ~isempty(Tda)
        disp(Tda(1:min(topN,height(Tda)), cols));
    else
        disp('<empty>');
    end

    fprintf('\n---- closest DT rows to threshold ----\n');
    Tdt = sortrows(Tdiag(abs(Tdiag.DT_margin_to_1) < inf, :), {'DT_margin_to_1','Ns'}, {'ascend','ascend'});
    if ~isempty(Tdt)
        disp(Tdt(1:min(topN,height(Tdt)), cols));
    else
        disp('<empty>');
    end

    fprintf('\n---- rows killed in joint from Stage05-compatible set ----\n');
    Tkill = sortrows(Tdiag(Tdiag.killed_in_joint, :), {'Ns','joint_margin','i_deg','P','T'}, {'ascend','ascend','ascend','ascend','ascend'});
    if ~isempty(Tkill)
        disp(Tkill(1:min(topN,height(Tkill)), cols));
    else
        disp('<empty>');
    end

    diag = struct();
    diag.diag_table = Tdiag;
    diag.summary_table = summary_table;
    diag.fail_summary = fail_summary;
    diag.files = struct();
    diag.files.diag_csv = diag_csv;
    diag.files.summary_csv = summary_csv;
    diag.files.fail_csv = fail_csv;
    diag.files.killed_da_csv = killed_da_csv;
    diag.files.killed_dt_csv = killed_dt_csv;
    diag.files.killed_joint_csv = killed_joint_csv;
end
