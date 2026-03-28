function out = manual_smoke_stage14_raan_sweep(cfg, overrides)
%MANUAL_SMOKE_STAGE14_RAAN_SWEEP
% Stage14.1C 最小非平凡性验证：
% 固定一个设计点，扫描 RAAN，观察 DG-only 指标是否随 RAAN 变化。
%
% 当前目标：
%   1) 不改主链；
%   2) 不画图；
%   3) 直接输出 table 和关键 span；
%   4) 优先验证 D_G_min / D_G_mean 是否存在非平凡波动。
%
% 说明：
%   - 这里故意关闭 early stop，避免“第一个 hard case 就失败”把差异淹没。
%   - 仍然复用当前工程里的 Stage02 / Stage04 cache 加载方式。
%   - 仍然复用 Stage05/14 当前 evaluator 链路。

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    % ------------------------------------------------------------
    % 1) 固定一个设计点，并设置 RAAN 扫描
    % ------------------------------------------------------------
    cfg = local_apply_smoke_overrides(cfg, overrides);
    cfg14 = stage14_default_config(cfg, overrides);

    % ------------------------------------------------------------
    % 2) 读取最新 Stage04 gamma_req（与 Stage14.1A/1B 一致）
    % ------------------------------------------------------------
    d4 = find_stage_cache_files(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
    assert(~isempty(d4), 'No Stage04 cache found. Please run stage04_window_worstcase first.');

    [~, idx4] = max([d4.datenum]);
    stage04_file = fullfile(d4(idx4).folder, d4(idx4).name);
    S4 = load(stage04_file);
    assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out');
    assert(isfield(S4.out, 'summary') && isfield(S4.out.summary, 'gamma_meta'), ...
        'Stage04 cache missing summary.gamma_meta');

    gamma_req = S4.out.summary.gamma_meta.gamma_req;
    cfg.stage04.gamma_req = gamma_req;
    cfg14.stage04.gamma_req = gamma_req;

    % ------------------------------------------------------------
    % 3) 读取最新 Stage02 nominal family
    % ------------------------------------------------------------
    d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
    assert(~isempty(d2), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');

    [~, idx2] = max([d2.datenum]);
    stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
    S2 = load(stage02_file);
    assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
        'Invalid Stage02 cache: missing out.trajbank.nominal');

    trajs_nominal = S2.out.trajbank.nominal;
    if isfinite(cfg14.stage14.case_limit) && cfg14.stage14.case_limit < numel(trajs_nominal)
        trajs_nominal = trajs_nominal(1:cfg14.stage14.case_limit);
    end

    % ------------------------------------------------------------
    % 4) hard-case-first 顺序（与 14.1A / 14.1B 一致）
    % ------------------------------------------------------------
    hard_order = (1:numel(trajs_nominal)).';
    if cfg14.stage14.hard_case_first
        try
            if isfield(S4.out.summary, 'margin') && isfield(S4.out.summary.margin, 'case_table')
                tab4 = S4.out.summary.margin.case_table;
            elseif isfield(S4.out.summary, 'spectrum') && isfield(S4.out.summary.spectrum, 'case_table')
                tab4 = S4.out.summary.spectrum.case_table;
            else
                tab4 = table();
            end

            if ~isempty(tab4)
                traj_case_ids = strings(numel(trajs_nominal),1);
                for k = 1:numel(trajs_nominal)
                    traj_case_ids(k) = string(trajs_nominal(k).case.case_id);
                end

                if ismember('case_ids', tab4.Properties.VariableNames) && ...
                   ismember('D_G', tab4.Properties.VariableNames) && ...
                   ismember('families', tab4.Properties.VariableNames)

                    nominal_rows = strcmp(string(tab4.families), "nominal");
                    tab_nom = tab4(nominal_rows, :);
                    [~, ord] = sort(tab_nom.D_G, 'ascend');

                    hard_ids = string(tab_nom.case_ids(ord));
                    hard_order_tmp = nan(numel(hard_ids),1);

                    for k = 1:numel(hard_ids)
                        idxk = find(traj_case_ids == hard_ids(k), 1);
                        if ~isempty(idxk)
                            hard_order_tmp(k) = idxk;
                        end
                    end

                    hard_order_tmp = hard_order_tmp(isfinite(hard_order_tmp));
                    if numel(hard_order_tmp) == numel(trajs_nominal)
                        hard_order = hard_order_tmp;
                    end
                end
            end
        catch
            % fallback silently
        end
    end

    % ------------------------------------------------------------
    % 5) 公共 eval_context
    % ------------------------------------------------------------
    eval_context = local_prepare_eval_context(trajs_nominal, cfg14);

    % ------------------------------------------------------------
    % 6) 生成 Stage14 grid，并逐个 RAAN 扫描
    % ------------------------------------------------------------
    grid14 = build_stage14_search_grid(cfg14);
    assert(height(grid14) >= 1, 'Stage14 grid is empty.');

    nGrid = height(grid14);

    rows = cell(nGrid, 10);
    res_cell = cell(nGrid, 1);

    for ig = 1:nGrid
        row14 = grid14(ig, :);
        row14.gamma_req = gamma_req;

        res14 = evaluate_single_layer_walker_stage14(row14, trajs_nominal, gamma_req, cfg14, hard_order, eval_context);
        res_cell{ig} = res14;

        rows(ig,:) = { ...
            row14.h_km, ...
            row14.i_deg, ...
            row14.P, ...
            row14.T, ...
            row14.F, ...
            row14.RAAN_deg, ...
            row14.Ns, ...
            res14.lambda_worst_min, ...
            res14.lambda_worst_mean, ...
            res14.D_G_min ...
            };
    end

    T = cell2table(rows, 'VariableNames', { ...
        'h_km','i_deg','P','T','F','RAAN_deg','Ns', ...
        'lambda_worst_min','lambda_worst_mean','D_G_min'});

    T.D_G_mean = nan(nGrid,1);
    T.pass_ratio = nan(nGrid,1);
    T.feasible_flag = false(nGrid,1);
    T.n_case_evaluated = nan(nGrid,1);
    T.failed_early = false(nGrid,1);

    for ig = 1:nGrid
        res14 = res_cell{ig};
        T.D_G_mean(ig) = res14.D_G_mean;
        T.pass_ratio(ig) = res14.pass_ratio;
        T.feasible_flag(ig) = logical(res14.feasible_flag);
        T.n_case_evaluated(ig) = res14.n_case_evaluated;
        T.failed_early(ig) = logical(res14.failed_early);
    end

    T = sortrows(T, 'RAAN_deg');

    summary = struct();
    summary.stage02_file = stage02_file;
    summary.stage04_file = stage04_file;
    summary.gamma_req = gamma_req;
    summary.case_count = numel(trajs_nominal);
    summary.RAAN_scan_deg = cfg14.stage14.RAAN_scan_deg;
    summary.lambda_worst_min_span = max(T.lambda_worst_min) - min(T.lambda_worst_min);
    summary.lambda_worst_mean_span = max(T.lambda_worst_mean) - min(T.lambda_worst_mean);
    summary.D_G_min_span = max(T.D_G_min) - min(T.D_G_min);
    summary.D_G_mean_span = max(T.D_G_mean) - min(T.D_G_mean);
    summary.pass_ratio_span = max(T.pass_ratio) - min(T.pass_ratio);

    out = struct();
    out.cfg = cfg14;
    out.table = T;
    out.summary = summary;
    out.results = res_cell;

    fprintf('\n=== Stage14.1C Minimal RAAN Sweep ===\n');
    fprintf('Stage02 cache        : %s\n', stage02_file);
    fprintf('Stage04 cache        : %s\n', stage04_file);
    fprintf('gamma_req            : %.12e\n', gamma_req);
    fprintf('Design               : h=%.1f, i=%.1f, P=%d, T=%d, F=%d\n', ...
        T.h_km(1), T.i_deg(1), T.P(1), T.T(1), T.F(1));
    fprintf('case_count           : %d\n', summary.case_count);
    fprintf('RAAN_scan_deg        : %s\n', mat2str(summary.RAAN_scan_deg));
    fprintf('lambda_worst_min span: %.12e\n', summary.lambda_worst_min_span);
    fprintf('lambda_worst_mean span: %.12e\n', summary.lambda_worst_mean_span);
    fprintf('D_G_min span         : %.12e\n', summary.D_G_min_span);
    fprintf('D_G_mean span        : %.12e\n', summary.D_G_mean_span);
    fprintf('pass_ratio span      : %.12e\n\n', summary.pass_ratio_span);

    disp(T);
end

function cfg = local_apply_smoke_overrides(cfg, overrides)
    if ~isfield(overrides, 'h_fixed_km'); overrides.h_fixed_km = cfg.stage05.h_fixed_km; end
    if ~isfield(overrides, 'i_grid_deg'); overrides.i_grid_deg = 60; end
    if ~isfield(overrides, 'P_grid'); overrides.P_grid = 4; end
    if ~isfield(overrides, 'T_grid'); overrides.T_grid = 6; end
    if ~isfield(overrides, 'F_fixed'); overrides.F_fixed = cfg.stage05.F_fixed; end
    if ~isfield(overrides, 'RAAN_scan_deg'); overrides.RAAN_scan_deg = 0:30:330; end

    % 这一轮优先看连续量，默认关闭 early stop
    if ~isfield(overrides, 'case_limit'); overrides.case_limit = inf; end
    if ~isfield(overrides, 'use_early_stop'); overrides.use_early_stop = false; end
    if ~isfield(overrides, 'hard_case_first'); overrides.hard_case_first = true; end
    if ~isfield(overrides, 'require_pass_ratio'); overrides.require_pass_ratio = cfg.stage05.require_pass_ratio; end
    if ~isfield(overrides, 'require_D_G_min'); overrides.require_D_G_min = cfg.stage05.require_D_G_min; end

    cfg.stage05.h_fixed_km = overrides.h_fixed_km;
    cfg.stage05.i_grid_deg = reshape(overrides.i_grid_deg, 1, []);
    cfg.stage05.P_grid = reshape(overrides.P_grid, 1, []);
    cfg.stage05.T_grid = reshape(overrides.T_grid, 1, []);
    cfg.stage05.F_fixed = overrides.F_fixed;
    cfg.stage05.use_early_stop = overrides.use_early_stop;
    cfg.stage05.hard_case_first = overrides.hard_case_first;
    cfg.stage05.require_pass_ratio = overrides.require_pass_ratio;
    cfg.stage05.require_D_G_min = overrides.require_D_G_min;
end

function eval_context = local_prepare_eval_context(trajs_in, cfg)
    t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
    t_max = max(t_end_all);
    dt = cfg.stage02.Ts_s;

    eval_context = struct();
    eval_context.t_s_common = (0:dt:t_max).';
end
