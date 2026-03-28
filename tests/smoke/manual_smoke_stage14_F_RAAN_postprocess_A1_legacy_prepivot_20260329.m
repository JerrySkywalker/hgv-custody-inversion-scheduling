function out = manual_smoke_stage14_F_RAAN_postprocess_A1_legacy_prepivot_20260329(out14FR, cfg, overrides)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
%MANUAL_SMOKE_STAGE14_F_RAAN_POSTPROCESS_A1_LEGACY_PREPIVOT_20260329
% Stage14 旧版探索归档（原正式第三步后处理）：
% 对 A1 的 (F,RAAN) 二维扫描结果做定量后处理。
%
% 输入：
%   out14FR : manual_smoke_stage14_F_RAAN_grid_A1 的输出结构
%
% 输出：
%   1) best-F-by-RAAN 三张曲线
%   2) RAAN-robust-stats-by-F 三张表
%   3) F=0 重复模式摘要
%
% 输出字段：
%   out.bestF_table
%   out.robust_stats_table
%   out.periodicity_F0
%   out.files

    if nargin < 1 || isempty(out14FR)
        error('out14FR is required. Run manual_smoke_stage14_F_RAAN_grid_A1 first.');
    end
    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 3 || isempty(overrides)
        overrides = struct();
    end

    if ~isfield(overrides, 'save_fig')
        overrides.save_fig = true;
    end
    if ~isfield(overrides, 'visible')
        overrides.visible = 'on';
    end

    % ------------------------------------------------------------
    % 1) 取数据
    % ------------------------------------------------------------
    F_values = out14FR.F_values(:);
    RAAN_values = out14FR.RAAN_values(:);

    pass_ratio_grid = out14FR.pass_ratio_grid;
    DG_mean_grid = out14FR.DG_mean_grid;
    DG_min_grid = out14FR.DG_min_grid;

    nF = numel(F_values);
    nR = numel(RAAN_values);

    % ------------------------------------------------------------
    % 2) 输出路径
    % ------------------------------------------------------------
    cfg.project_stage = 'stage14_plot_F_RAAN_postprocess';
    cfg = configure_stage_output_paths(cfg);
    fig_dir = cfg.paths.stage_figs;
    if ~exist(fig_dir, 'dir')
        mkdir(fig_dir);
    end
    ts = datestr(now, 'yyyymmdd_HHMMSS');

    % ------------------------------------------------------------
    % 3) best-F-by-RAAN
    % ------------------------------------------------------------
    [pass_ratio_best_val, idx_best_pass] = max(pass_ratio_grid, [], 1);
    [DG_mean_best_val, idx_best_dgm] = max(DG_mean_grid, [], 1);
    [DG_min_best_val, idx_best_dgmin] = max(DG_min_grid, [], 1);

    bestF_pass = F_values(idx_best_pass);
    bestF_dgm = F_values(idx_best_dgm);
    bestF_dgmin = F_values(idx_best_dgmin);

    bestF_table = table( ...
        RAAN_values, ...
        bestF_pass, pass_ratio_best_val(:), ...
        bestF_dgm,  DG_mean_best_val(:), ...
        bestF_dgmin, DG_min_best_val(:), ...
        'VariableNames', { ...
            'RAAN_deg', ...
            'bestF_pass_ratio', 'best_pass_ratio', ...
            'bestF_DG_mean', 'best_DG_mean', ...
            'bestF_DG_min', 'best_DG_min' ...
        });

    % ------------------------------------------------------------
    % 4) RAAN-robust-stats-by-F
    % ------------------------------------------------------------
    rows = cell(0, 16);
    for iF = 1:nF
        Fk = F_values(iF);

        pr = pass_ratio_grid(iF, :).';
        dgm = DG_mean_grid(iF, :).';
        dgmin = DG_min_grid(iF, :).';

        rows(end+1,:) = { ...
            Fk, ...
            mean(pr), min(pr), max(pr), max(pr)-min(pr), ...
            mean(dgm), min(dgm), max(dgm), max(dgm)-min(dgm), ...
            mean(dgmin), min(dgmin), max(dgmin), max(dgmin)-min(dgmin), ...
            std(pr), std(dgm), std(dgmin) ...
            }; %#ok<AGROW>
    end

    robust_stats_table = cell2table(rows, 'VariableNames', { ...
        'F', ...
        'pass_ratio_mean','pass_ratio_min','pass_ratio_max','pass_ratio_span', ...
        'DG_mean_mean','DG_mean_min','DG_mean_max','DG_mean_span', ...
        'DG_min_mean','DG_min_min','DG_min_max','DG_min_span', ...
        'pass_ratio_std','DG_mean_std','DG_min_std' ...
    });

    % ------------------------------------------------------------
    % 5) F=0 周期重复摘要
    % ------------------------------------------------------------
    idxF0 = find(F_values == 0, 1);
    periodicity_F0 = struct();

    if ~isempty(idxF0)
        row_pr = pass_ratio_grid(idxF0, :).';
        row_dgm = DG_mean_grid(idxF0, :).';
        row_dgmin = DG_min_grid(idxF0, :).';

        periodicity_F0.pass_ratio = local_periodicity_summary(RAAN_values, row_pr);
        periodicity_F0.DG_mean = local_periodicity_summary(RAAN_values, row_dgm);
        periodicity_F0.DG_min = local_periodicity_summary(RAAN_values, row_dgmin);
    else
        warning('F=0 not found in F_values.');
    end

    % ------------------------------------------------------------
    % 6) 绘图：best-F-by-RAAN
    % ------------------------------------------------------------
    fig_bestF = figure('Name', 'Stage14 best F by RAAN, A1', ...
        'NumberTitle', 'off', 'Visible', overrides.visible);

    tiledlayout(3,1);

    nexttile;
    plot(RAAN_values, bestF_pass, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
    grid on; box on;
    ylabel('best F');
    title('best F by RAAN: pass ratio');

    nexttile;
    plot(RAAN_values, bestF_dgm, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
    grid on; box on;
    ylabel('best F');
    title('best F by RAAN: D_G mean');

    nexttile;
    plot(RAAN_values, bestF_dgmin, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
    grid on; box on;
    xlabel('RAAN (deg)');
    ylabel('best F');
    title('best F by RAAN: D_G min');

    files = struct();
    files.fig_dir = fig_dir;
    files.bestF_png = '';

    if overrides.save_fig
        files.bestF_png = fullfile(fig_dir, sprintf('stage14_A1_bestF_by_RAAN_%s.png', ts));
        exportgraphics(fig_bestF, files.bestF_png, 'Resolution', 220);
    end

    % ------------------------------------------------------------
    % 7) 汇总输出
    % ------------------------------------------------------------
    out = struct();
    out.bestF_table = bestF_table;
    out.robust_stats_table = robust_stats_table;
    out.periodicity_F0 = periodicity_F0;
    out.files = files;

    fprintf('\n=== Stage14 A1 (F,RAAN) Postprocess ===\n');
    fprintf('figure dir         : %s\n', files.fig_dir);
    fprintf('bestF png          : %s\n\n', files.bestF_png);

    fprintf('--- bestF_table (head) ---\n');
    disp(bestF_table(1:min(24,height(bestF_table)), :));

    fprintf('--- robust_stats_table ---\n');
    disp(robust_stats_table);

    if ~isempty(idxF0)
        fprintf('--- periodicity_F0.pass_ratio ---\n');
        disp(periodicity_F0.pass_ratio);
        fprintf('--- periodicity_F0.DG_mean ---\n');
        disp(periodicity_F0.DG_mean);
        fprintf('--- periodicity_F0.DG_min ---\n');
        disp(periodicity_F0.DG_min);
    end
end

function S = local_periodicity_summary(RAAN_values, y)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    S = struct();

    S.unique_values_count = numel(unique(round(y, 10)));
    S.span = max(y) - min(y);

    S.max_abs_delta45 = local_shift_delta_maxabs(RAAN_values, y, 45);
    S.max_abs_delta90 = local_shift_delta_maxabs(RAAN_values, y, 90);
    S.max_abs_delta180 = local_shift_delta_maxabs(RAAN_values, y, 180);

    % 针对当前 15° 采样，也补一个 30° 的摘要，便于判断 45° 的子结构
    S.max_abs_delta30 = local_shift_delta_maxabs(RAAN_values, y, 30);
end

function d = local_shift_delta_maxabs(RAAN_values, y, shift_deg)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    r = RAAN_values(:);
    y = y(:);

    vals = nan(numel(r),1);
    for k = 1:numel(r)
        target = mod(r(k) + shift_deg, 360);
        idx = find(r == target, 1);
        if ~isempty(idx)
            vals(k) = y(idx) - y(k);
        end
    end
    d = max(abs(vals), [], 'omitnan');
end

