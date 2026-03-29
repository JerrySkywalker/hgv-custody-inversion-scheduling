function out = manual_smoke_stage14_F_RAAN_grid_A1_legacy_prepivot_20260329(cfg, overrides)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
%MANUAL_SMOKE_STAGE14_F_RAAN_GRID_A1_LEGACY_PREPIVOT_20260329
% Stage14 旧版探索归档（原正式第二步分析脚本）：
% 对 A1 在 (F, RAAN) 上做二维扫描，并输出三张热图：
%   1) pass_ratio(F, RAAN)
%   2) D_G_mean(F, RAAN)
%   3) D_G_min(F, RAAN)
%
% A1 baseline geometry:
%   h=1000, i=40, P=8, T=6
%
% 输出：
%   out.summary_table
%   out.pass_ratio_grid
%   out.DG_mean_grid
%   out.DG_min_grid
%   out.files

    if nargin < 1 || isempty(cfg)
        evalc('startup();');
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    % ------------------------------------------------------------
    % 1) 默认参数
    % ------------------------------------------------------------
    if ~isfield(overrides, 'h_fixed_km')
        overrides.h_fixed_km = 1000;
    end
    if ~isfield(overrides, 'i_deg')
        overrides.i_deg = 40;
    end
    if ~isfield(overrides, 'P')
        overrides.P = 8;
    end
    if ~isfield(overrides, 'T')
        overrides.T = 6;
    end
    if ~isfield(overrides, 'F_values')
        overrides.F_values = 0:(overrides.P-1);
    end
    if ~isfield(overrides, 'RAAN_values')
        overrides.RAAN_values = 0:15:345;
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
    if ~isfield(overrides, 'save_fig')
        overrides.save_fig = true;
    end
    if ~isfield(overrides, 'visible')
        overrides.visible = 'on';
    end

    % ------------------------------------------------------------
    % 2) 输出路径
    % ------------------------------------------------------------
    cfg.project_stage = 'stage14_plot_F_RAAN_grid';
    cfg = configure_stage_output_paths(cfg);
    fig_dir = cfg.paths.stage_figs;
    if ~exist(fig_dir, 'dir')
        mkdir(fig_dir);
    end
    ts = datestr(now, 'yyyymmdd_HHMMSS');

    % ------------------------------------------------------------
    % 3) 加载 Stage04 gamma_req
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

    % ------------------------------------------------------------
    % 4) 加载 Stage02 nominal family
    % ------------------------------------------------------------
    d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
    assert(~isempty(d2), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');

    [~, idx2] = max([d2.datenum]);
    stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
    S2 = load(stage02_file);
    assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
        'Invalid Stage02 cache: missing out.trajbank.nominal');

    trajs_nominal = S2.out.trajbank.nominal;
    if isfinite(overrides.case_limit) && overrides.case_limit < numel(trajs_nominal)
        trajs_nominal = trajs_nominal(1:overrides.case_limit);
    end

    % ------------------------------------------------------------
    % 5) hard-case-first 顺序
    % ------------------------------------------------------------
    hard_order = (1:numel(trajs_nominal)).';
    if overrides.hard_case_first
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
    % 6) eval_context
    % ------------------------------------------------------------
    eval_context = local_prepare_eval_context(trajs_nominal, cfg);

    % ------------------------------------------------------------
    % 7) 扫 (F, RAAN)
    % ------------------------------------------------------------
    F_values = overrides.F_values(:).';
    RAAN_values = overrides.RAAN_values(:).';

    nF = numel(F_values);
    nR = numel(RAAN_values);

    rows = cell(0, 11);

    pass_ratio_grid = nan(nF, nR);
    DG_mean_grid = nan(nF, nR);
    DG_min_grid = nan(nF, nR);

    for iF = 1:nF
        Fk = F_values(iF);

        for iR = 1:nR
            Rk = RAAN_values(iR);

            cfg14 = stage14_default_config(cfg, struct( ...
                'h_fixed_km', overrides.h_fixed_km, ...
                'i_grid_deg', overrides.i_deg, ...
                'P_grid', overrides.P, ...
                'T_grid', overrides.T, ...
                'F_fixed', Fk, ...
                'RAAN_scan_deg', Rk, ...
                'use_early_stop', overrides.use_early_stop, ...
                'hard_case_first', overrides.hard_case_first, ...
                'require_pass_ratio', overrides.require_pass_ratio, ...
                'require_D_G_min', overrides.require_D_G_min, ...
                'case_limit', overrides.case_limit));

            grid14 = build_stage14_search_grid(cfg14);
            assert(height(grid14) == 1, 'Expected exactly one design point in A1 (F,RAAN) scan.');

            row14 = grid14(1,:);
            row14.gamma_req = gamma_req;

            res14 = evaluate_single_layer_walker_stage14(row14, trajs_nominal, gamma_req, cfg14, hard_order, eval_context);

            pass_ratio_grid(iF, iR) = res14.pass_ratio;
            DG_mean_grid(iF, iR) = res14.D_G_mean;
            DG_min_grid(iF, iR) = res14.D_G_min;

            rows(end+1,:) = { ...
                overrides.h_fixed_km, ...
                overrides.i_deg, ...
                overrides.P, ...
                overrides.T, ...
                Fk, ...
                Rk, ...
                overrides.P * overrides.T, ...
                res14.D_G_min, ...
                res14.D_G_mean, ...
                res14.pass_ratio, ...
                res14.feasible_flag ...
                }; %#ok<AGROW>
        end
    end

    summary_table = cell2table(rows, 'VariableNames', { ...
        'h_km','i_deg','P','T','F','RAAN_deg','Ns','D_G_min','D_G_mean','pass_ratio','feasible_flag'});

    summary_table = sortrows(summary_table, {'F','RAAN_deg'});

    % ------------------------------------------------------------
    % 8) 热图
    % ------------------------------------------------------------
    fig_pass = figure('Name', 'Stage14 pass ratio heatmap', ...
        'NumberTitle', 'off', 'Visible', overrides.visible);
    imagesc(RAAN_values, F_values, pass_ratio_grid);
    axis xy; colorbar;
    xlabel('RAAN (deg)');
    ylabel('F');
    title('Stage14 DG-only sensitivity: pass ratio(F,\Omega), A1');

    fig_dgm = figure('Name', 'Stage14 D_G_mean heatmap', ...
        'NumberTitle', 'off', 'Visible', overrides.visible);
    imagesc(RAAN_values, F_values, DG_mean_grid);
    axis xy; colorbar;
    xlabel('RAAN (deg)');
    ylabel('F');
    title('Stage14 DG-only sensitivity: D_G mean(F,\Omega), A1');

    fig_dgmin = figure('Name', 'Stage14 D_G_min heatmap', ...
        'NumberTitle', 'off', 'Visible', overrides.visible);
    imagesc(RAAN_values, F_values, DG_min_grid);
    axis xy; colorbar;
    xlabel('RAAN (deg)');
    ylabel('F');
    title('Stage14 DG-only sensitivity: D_G min(F,\Omega), A1');

    files = struct();
    files.fig_dir = fig_dir;
    files.pass_ratio_png = '';
    files.DG_mean_png = '';
    files.DG_min_png = '';

    if overrides.save_fig
        files.pass_ratio_png = fullfile(fig_dir, sprintf('stage14_A1_pass_ratio_F_RAAN_%s.png', ts));
        files.DG_mean_png = fullfile(fig_dir, sprintf('stage14_A1_DG_mean_F_RAAN_%s.png', ts));
        files.DG_min_png = fullfile(fig_dir, sprintf('stage14_A1_DG_min_F_RAAN_%s.png', ts));

        exportgraphics(fig_pass, files.pass_ratio_png, 'Resolution', 220);
        exportgraphics(fig_dgm, files.DG_mean_png, 'Resolution', 220);
        exportgraphics(fig_dgmin, files.DG_min_png, 'Resolution', 220);
    end

    out = struct();
    out.summary_table = summary_table;
    out.pass_ratio_grid = pass_ratio_grid;
    out.DG_mean_grid = DG_mean_grid;
    out.DG_min_grid = DG_min_grid;
    out.F_values = F_values;
    out.RAAN_values = RAAN_values;
    out.files = files;
    out.stage02_file = stage02_file;
    out.stage04_file = stage04_file;
    out.gamma_req = gamma_req;

    fprintf('\n=== Stage14 (F,RAAN) Grid: A1 ===\n');
    fprintf('Stage02 cache      : %s\n', stage02_file);
    fprintf('Stage04 cache      : %s\n', stage04_file);
    fprintf('gamma_req          : %.12e\n', gamma_req);
    fprintf('figure dir         : %s\n', files.fig_dir);
    fprintf('pass_ratio png     : %s\n', files.pass_ratio_png);
    fprintf('D_G_mean png       : %s\n', files.DG_mean_png);
    fprintf('D_G_min png        : %s\n\n', files.DG_min_png);

    fprintf('Grid size          : %d x %d (F x RAAN)\n', nF, nR);
    fprintf('pass_ratio range   : [%.12g, %.12g]\n', min(pass_ratio_grid, [], 'all'), max(pass_ratio_grid, [], 'all'));
    fprintf('D_G_mean range     : [%.12g, %.12g]\n', min(DG_mean_grid, [], 'all'), max(DG_mean_grid, [], 'all'));
    fprintf('D_G_min range      : [%.12g, %.12g]\n\n', min(DG_min_grid, [], 'all'), max(DG_min_grid, [], 'all'));

    fprintf('--- summary_table (head) ---\n');
    disp(summary_table(1:min(24,height(summary_table)), :));
end

function eval_context = local_prepare_eval_context(trajs_in, cfg)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
    t_max = max(t_end_all);
    dt = cfg.stage02.Ts_s;

    eval_context = struct();
    eval_context.t_s_common = (0:dt:t_max).';
end
