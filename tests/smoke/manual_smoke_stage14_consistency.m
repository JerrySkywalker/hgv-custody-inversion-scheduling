function out = manual_smoke_stage14_consistency(cfg, overrides)
%MANUAL_SMOKE_STAGE14_CONSISTENCY
% Stage14.1B 一致性验证：
% 在完全复用 Stage05 数据加载与 hard-case-first 逻辑的前提下，
% 比较同一设计点上：
%   - Stage05 evaluator
%   - Stage14 evaluator (RAAN = 0)
% 的输出是否一致。
%
% 目的：
%   验证 Stage14 在 RAAN=0 时，是否严格退化回 Stage05。
%
% 使用建议：
%   先用小样本 + early stop 做最小一致性验证；
%   再用 full nominal family 做严格一致性验证。

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    % ------------------------------------------------------------
    % 1) 统一 Stage05 / Stage14 的测试配置
    % ------------------------------------------------------------
    cfg = local_apply_smoke_overrides(cfg, overrides);
    cfg14 = stage14_default_config(cfg, overrides);

    % ------------------------------------------------------------
    % 2) 按 Stage05 的真实写法加载 Stage04 gamma_req
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
    % 3) 按 Stage05 的真实写法加载 Stage02 nominal family
    % ------------------------------------------------------------
    d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
    assert(~isempty(d2), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');

    [~, idx2] = max([d2.datenum]);
    stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
    S2 = load(stage02_file);
    assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
        'Invalid Stage02 cache: missing out.trajbank.nominal');

    trajs_nominal = S2.out.trajbank.nominal;

    if isfield(overrides, 'case_limit') && isfinite(overrides.case_limit) && overrides.case_limit < numel(trajs_nominal)
        trajs_nominal = trajs_nominal(1:overrides.case_limit);
    end

    % ------------------------------------------------------------
    % 4) 按 Stage05 的真实写法构造 hard-case-first 顺序
    % ------------------------------------------------------------
    hard_order = (1:numel(trajs_nominal)).';
    if cfg.stage05.hard_case_first
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
            % fallback silently, exactly as Stage05
        end
    end

    % ------------------------------------------------------------
    % 5) 与 Stage05 一样准备公共 eval_context
    % ------------------------------------------------------------
    eval_context = local_prepare_eval_context(trajs_nominal, cfg);

    % ------------------------------------------------------------
    % 6) 构造同一设计点的 Stage05 / Stage14 row
    % ------------------------------------------------------------
    grid05 = build_stage05_search_grid(cfg);
    assert(height(grid05) >= 1, 'Stage05 search grid is empty.');

    row05 = grid05(1,:);
    row05.gamma_req = gamma_req;

    grid14 = build_stage14_search_grid(cfg14);

    mask14 = ...
        grid14.h_km == row05.h_km & ...
        grid14.i_deg == row05.i_deg & ...
        grid14.P == row05.P & ...
        grid14.T == row05.T & ...
        grid14.F == row05.F & ...
        grid14.RAAN_deg == 0;

    assert(any(mask14), 'No matching Stage14 row found for Stage05 row with RAAN=0.');

    row14 = grid14(find(mask14, 1, 'first'), :);
    row14.gamma_req = gamma_req;

    % ------------------------------------------------------------
    % 7) 分别调用 Stage05 / Stage14 evaluator
    % ------------------------------------------------------------
    res05 = evaluate_single_layer_walker_stage05(row05, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
    res14 = evaluate_single_layer_walker_stage14(row14, trajs_nominal, gamma_req, cfg14, hard_order, eval_context);

    % ------------------------------------------------------------
    % 8) 汇总对比
    % ------------------------------------------------------------
    cmp = table( ...
        ["lambda_worst_min"; "lambda_worst_mean"; "D_G_min"; "D_G_mean"; "pass_ratio"; "rank_score"; "n_case_evaluated"; "failed_early"; "feasible_flag"], ...
        [res05.lambda_worst_min; res05.lambda_worst_mean; res05.D_G_min; res05.D_G_mean; res05.pass_ratio; res05.rank_score; res05.n_case_evaluated; double(res05.failed_early); double(res05.feasible_flag)], ...
        [res14.lambda_worst_min; res14.lambda_worst_mean; res14.D_G_min; res14.D_G_mean; res14.pass_ratio; res14.rank_score; res14.n_case_evaluated; double(res14.failed_early); double(res14.feasible_flag)], ...
        'VariableNames', {'metric', 'stage05', 'stage14_raan0'} ...
    );
    cmp.abs_diff = abs(cmp.stage05 - cmp.stage14_raan0);

    tol = 1e-12;
    cmp.is_equal = cmp.abs_diff <= tol;

    % case_table 对比（只比已评估到的 case 行）
    case_cmp = local_compare_case_table(res05.case_table, res14.case_table);

    out = struct();
    out.stage02_file = stage02_file;
    out.stage04_file = stage04_file;
    out.gamma_req = gamma_req;
    out.row05 = row05;
    out.row14 = row14;
    out.res05 = res05;
    out.res14 = res14;
    out.cmp = cmp;
    out.case_cmp = case_cmp;
    out.all_equal = all(cmp.is_equal) && all(case_cmp.is_equal);

    fprintf('\n=== Stage14.1B Consistency Check ===\n');
    fprintf('Stage02 cache : %s\n', stage02_file);
    fprintf('Stage04 cache : %s\n', stage04_file);
    fprintf('gamma_req     : %.12e\n', gamma_req);
    fprintf('Design        : h=%.1f, i=%.1f, P=%d, T=%d, F=%d, RAAN=0\n', ...
        row05.h_km, row05.i_deg, row05.P, row05.T, row05.F);
    fprintf('case_count    : %d\n', numel(trajs_nominal));
    fprintf('all_equal     : %d\n\n', logical(out.all_equal));

    disp(cmp);
    disp(case_cmp);
end

function cfg = local_apply_smoke_overrides(cfg, overrides)
    % 这一层只控制“同一个设计点”的 Stage05/Stage14 对照
    % 缺省取一个最小设计点，便于先做最小一致性验证

    if ~isfield(overrides, 'h_fixed_km'); overrides.h_fixed_km = cfg.stage05.h_fixed_km; end
    if ~isfield(overrides, 'i_grid_deg'); overrides.i_grid_deg = cfg.stage05.i_grid_deg(1); end
    if ~isfield(overrides, 'P_grid'); overrides.P_grid = cfg.stage05.P_grid(1); end
    if ~isfield(overrides, 'T_grid'); overrides.T_grid = cfg.stage05.T_grid(1); end
    if ~isfield(overrides, 'F_fixed'); overrides.F_fixed = cfg.stage05.F_fixed; end
    if ~isfield(overrides, 'RAAN_scan_deg'); overrides.RAAN_scan_deg = 0; end
    if ~isfield(overrides, 'case_limit'); overrides.case_limit = inf; end
    if ~isfield(overrides, 'use_early_stop'); overrides.use_early_stop = cfg.stage05.use_early_stop; end
    if ~isfield(overrides, 'hard_case_first'); overrides.hard_case_first = cfg.stage05.hard_case_first; end
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

function case_cmp = local_compare_case_table(tab05, tab14)
    vars_to_compare = {'lambda_worst', 'D_G', 'pass_flag', 't0_worst', 'mean_vis', 'dual_ratio'};
    n = height(tab05);

    metric = strings(0,1);
    stage05 = [];
    stage14_raan0 = [];
    case_id = strings(0,1);

    for i = 1:n
        cid = string(tab05.case_id(i));
        for v = 1:numel(vars_to_compare)
            vn = vars_to_compare{v};

            a = tab05.(vn)(i);
            b = tab14.(vn)(i);

            if islogical(a), a = double(a); end
            if islogical(b), b = double(b); end

            if ~(isnan(a) && isnan(b))
                metric(end+1,1) = string(vn); %#ok<AGROW>
                stage05(end+1,1) = a; %#ok<AGROW>
                stage14_raan0(end+1,1) = b; %#ok<AGROW>
                case_id(end+1,1) = cid; %#ok<AGROW>
            end
        end
    end

    case_cmp = table(case_id, metric, stage05, stage14_raan0);
    case_cmp.abs_diff = abs(case_cmp.stage05 - case_cmp.stage14_raan0);
    case_cmp.is_equal = case_cmp.abs_diff <= 1e-12;
end
