function out = manual_smoke_stage14_batch_raan_sweep(cfg, overrides)
%MANUAL_SMOKE_STAGE14_BATCH_RAAN_SWEEP
% Stage14.1E:
% 对一组候选设计点批量做 RAAN sweep，并输出统一总表。
%
% 当前目标：
%   1) 不改正式 stage；
%   2) 批量比较多组候选点；
%   3) 先输出 table 和 summary，不画图；
%   4) 找出真正值得进入正式 Stage14 图表开发的点。
%
% 默认候选点（来自 Stage14.1D 推荐）：
%   #1  h=1000, i=40, P=8, T=6,  F=1, Ns=48
%   #2  h=1000, i=30, P=6, T=8,  F=1, Ns=48
%   #3  h=1000, i=30, P=8, T=6,  F=1, Ns=48
%   #4  h=1000, i=30, P=6, T=10, F=1, Ns=60
%
% 输出：
%   out.summary_table : 每个设计点的 span / max / min 摘要
%   out.detail_table  : 每个设计点、每个 RAAN 的逐点结果
%   out.config_table  : 候选点配置表

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    if ~isfield(overrides, 'RAAN_scan_deg')
        overrides.RAAN_scan_deg = 0:30:330;
    end
    if ~isfield(overrides, 'case_limit')
        overrides.case_limit = inf;
    end
    if ~isfield(overrides, 'use_early_stop')
        overrides.use_early_stop = false;
    end
    if ~isfield(overrides, 'hard_case_first')
        overrides.hard_case_first = true;
    end
    if ~isfield(overrides, 'require_pass_ratio')
        overrides.require_pass_ratio = 1.0;
    end
    if ~isfield(overrides, 'require_D_G_min')
        overrides.require_D_G_min = 1.0;
    end

    % ------------------------------------------------------------
    % 1) 候选设计点表
    % ------------------------------------------------------------
    if isfield(overrides, 'config_table') && istable(overrides.config_table) && ~isempty(overrides.config_table)
        config_table = overrides.config_table;
    else
        config_table = table( ...
            [1000; 1000; 1000; 1000], ...   % h_km
            [40;   30;   30;   30], ...     % i_deg
            [8;    6;    8;    6], ...      % P
            [6;    8;    6;   10], ...      % T
            [1;    1;    1;    1], ...      % F
            ["A1_Ns48_i40_P8_T6"; ...
             "A2_Ns48_i30_P6_T8"; ...
             "B1_Ns48_i30_P8_T6"; ...
             "C1_Ns60_i30_P6_T10"], ...
            'VariableNames', {'h_km','i_deg','P','T','F','tag'} ...
        );
    end

    if ~ismember('Ns', config_table.Properties.VariableNames)
        config_table.Ns = config_table.P .* config_table.T;
    end

    % ------------------------------------------------------------
    % 2) 初始化输出容器
    % ------------------------------------------------------------
    detail_varnames = { ...
        'tag','h_km','i_deg','P','T','F','Ns','RAAN_deg', ...
        'lambda_worst_min','lambda_worst_mean','D_G_min','D_G_mean','pass_ratio', ...
        'feasible_flag','n_case_evaluated','failed_early'};

    summary_varnames = { ...
        'tag','h_km','i_deg','P','T','F','Ns','case_count', ...
        'lambda_worst_min_span','lambda_worst_mean_span','D_G_min_span','D_G_mean_span','pass_ratio_span', ...
        'D_G_mean_max','RAAN_at_D_G_mean_max', ...
        'D_G_mean_min','RAAN_at_D_G_mean_min', ...
        'D_G_min_max','RAAN_at_D_G_min_max', ...
        'D_G_min_min','RAAN_at_D_G_min_min', ...
        'pass_ratio_max','RAAN_at_pass_ratio_max', ...
        'pass_ratio_min','RAAN_at_pass_ratio_min'};

    detail_rows = cell(0, numel(detail_varnames));
    summary_rows = cell(0, numel(summary_varnames));
    sweep_outputs = cell(height(config_table),1);

    % ------------------------------------------------------------
    % 3) 逐设计点调用 14.1C
    % ------------------------------------------------------------
    for ic = 1:height(config_table)
        rowc = config_table(ic,:);

        local_overrides = struct();
        local_overrides.h_fixed_km = rowc.h_km;
        local_overrides.i_grid_deg = rowc.i_deg;
        local_overrides.P_grid = rowc.P;
        local_overrides.T_grid = rowc.T;
        local_overrides.F_fixed = rowc.F;
        local_overrides.RAAN_scan_deg = overrides.RAAN_scan_deg;
        local_overrides.case_limit = overrides.case_limit;
        local_overrides.use_early_stop = overrides.use_early_stop;
        local_overrides.hard_case_first = overrides.hard_case_first;
        local_overrides.require_pass_ratio = overrides.require_pass_ratio;
        local_overrides.require_D_G_min = overrides.require_D_G_min;

        sweep_out = manual_smoke_stage14_raan_sweep(cfg, local_overrides);
        sweep_outputs{ic} = sweep_out;

        T = sweep_out.table;
        nT = height(T);

        for ir = 1:nT
            detail_row = { ...
                rowc.tag, ...
                T.h_km(ir), ...
                T.i_deg(ir), ...
                T.P(ir), ...
                T.T(ir), ...
                T.F(ir), ...
                T.Ns(ir), ...
                T.RAAN_deg(ir), ...
                T.lambda_worst_min(ir), ...
                T.lambda_worst_mean(ir), ...
                T.D_G_min(ir), ...
                T.D_G_mean(ir), ...
                T.pass_ratio(ir), ...
                T.feasible_flag(ir), ...
                T.n_case_evaluated(ir), ...
                T.failed_early(ir) ...
                };
            assert(numel(detail_row) == numel(detail_varnames), 'detail_row width mismatch.');
            detail_rows(end+1,:) = detail_row;
        end

        s = sweep_out.summary;
        [dgm_max, idx_dgm_max] = max(T.D_G_mean);
        [dgm_min, idx_dgm_min] = min(T.D_G_mean);
        [dgp_max, idx_dgp_max] = max(T.D_G_min);
        [dgp_min, idx_dgp_min] = min(T.D_G_min);
        [pr_max, idx_pr_max] = max(T.pass_ratio);
        [pr_min, idx_pr_min] = min(T.pass_ratio);

        summary_row = { ...
            rowc.tag, ...
            rowc.h_km, ...
            rowc.i_deg, ...
            rowc.P, ...
            rowc.T, ...
            rowc.F, ...
            rowc.Ns, ...
            s.case_count, ...
            s.lambda_worst_min_span, ...
            s.lambda_worst_mean_span, ...
            s.D_G_min_span, ...
            s.D_G_mean_span, ...
            s.pass_ratio_span, ...
            dgm_max, T.RAAN_deg(idx_dgm_max), ...
            dgm_min, T.RAAN_deg(idx_dgm_min), ...
            dgp_max, T.RAAN_deg(idx_dgp_max), ...
            dgp_min, T.RAAN_deg(idx_dgp_min), ...
            pr_max, T.RAAN_deg(idx_pr_max), ...
            pr_min, T.RAAN_deg(idx_pr_min) ...
            };
        assert(numel(summary_row) == numel(summary_varnames), 'summary_row width mismatch.');
        summary_rows(end+1,:) = summary_row;
    end

    % ------------------------------------------------------------
    % 4) 拼成表
    % ------------------------------------------------------------
    detail_table = cell2table(detail_rows, 'VariableNames', detail_varnames);
    summary_table = cell2table(summary_rows, 'VariableNames', summary_varnames);

    summary_table = sortrows(summary_table, {'D_G_min_span','D_G_mean_span','pass_ratio_span'}, {'descend','descend','descend'});
    detail_table = sortrows(detail_table, {'tag','RAAN_deg'}, {'ascend','ascend'});

    out = struct();
    out.config_table = config_table;
    out.summary_table = summary_table;
    out.detail_table = detail_table;
    out.sweep_outputs = sweep_outputs;

    fprintf('\n=== Stage14.1E Batch Candidate RAAN Sweep ===\n');
    fprintf('candidate_count : %d\n', height(config_table));
    fprintf('RAAN_scan_deg   : %s\n', mat2str(overrides.RAAN_scan_deg));
    fprintf('case_limit      : %g\n', overrides.case_limit);
    fprintf('use_early_stop  : %d\n\n', logical(overrides.use_early_stop));

    fprintf('--- summary_table ---\n');
    disp(summary_table);

    fprintf('--- detail_table (head) ---\n');
    disp(detail_table(1:min(40,height(detail_table)), :));
end
