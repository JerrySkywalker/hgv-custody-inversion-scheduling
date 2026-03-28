function out = manual_smoke_stage14_plot_profiles(cfg, overrides)
%MANUAL_SMOKE_STAGE14_PLOT_PROFILES
% Stage14.2B:
% 在现有两张正式 RAAN 曲线图基础上，补第三张：
%   1) pass_ratio vs RAAN
%   2) D_G_mean vs RAAN
%   3) D_G_min  vs RAAN
%
% 当前仅针对两个主候选点：
%   - A1_Ns48_i40_P8_T6
%   - A2_Ns48_i30_P6_T8
%
% 输出：
%   out.summary_table
%   out.detail_table
%   out.fig_pass_ratio
%   out.fig_DG_mean
%   out.fig_DG_min
%   out.files

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    % ------------------------------------------------------------
    % 1) 默认绘图配置
    % ------------------------------------------------------------
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
    if ~isfield(overrides, 'save_fig')
        overrides.save_fig = true;
    end
    if ~isfield(overrides, 'visible')
        overrides.visible = 'on';
    end

    % ------------------------------------------------------------
    % 2) 输出路径：遵循当前工程习惯
    % ------------------------------------------------------------
    cfg.project_stage = 'stage14_plot_raan_profiles';
    cfg = configure_stage_output_paths(cfg);

    fig_dir = cfg.paths.stage_figs;
    if ~exist(fig_dir, 'dir')
        mkdir(fig_dir);
    end

    % ------------------------------------------------------------
    % 3) 只取两个主候选点
    % ------------------------------------------------------------
    config_table = table( ...
        [1000; 1000], ...
        [40;   30], ...
        [8;    6], ...
        [6;    8], ...
        [1;    1], ...
        ["A1_Ns48_i40_P8_T6"; ...
         "A2_Ns48_i30_P6_T8"], ...
        'VariableNames', {'h_km','i_deg','P','T','F','tag'} ...
    );
    config_table.Ns = config_table.P .* config_table.T;
    overrides.config_table = config_table;

    % ------------------------------------------------------------
    % 4) 调用批量 sweep
    % ------------------------------------------------------------
    sweep_out = manual_smoke_stage14_batch_raan_sweep(cfg, overrides);

    detail_table = sweep_out.detail_table;
    summary_table = sweep_out.summary_table;

    ts = datestr(now, 'yyyymmdd_HHMMSS');

    % 论文友好图例
    pretty_names = containers.Map( ...
        {'A1_Ns48_i40_P8_T6','A2_Ns48_i30_P6_T8'}, ...
        {'N_s=48, (P,T)=(8,6), i=40°', ...
         'N_s=48, (P,T)=(6,8), i=30°'} ...
    );

    tags = unique(detail_table.tag, 'stable');

    % ------------------------------------------------------------
    % 5) 图 1：pass_ratio vs RAAN
    % ------------------------------------------------------------
    fig_pass = figure('Name', 'Stage14 pass ratio vs RAAN', ...
        'NumberTitle', 'off', 'Visible', overrides.visible);
    hold on; grid on; box on;

    for it = 1:numel(tags)
        sub = detail_table(detail_table.tag == tags(it), :);
        sub = sortrows(sub, 'RAAN_deg');
        if isKey(pretty_names, char(tags(it)))
            disp_name = pretty_names(char(tags(it)));
        else
            disp_name = char(tags(it));
        end
        plot(sub.RAAN_deg, sub.pass_ratio, '-o', ...
            'LineWidth', 1.5, 'MarkerSize', 6, ...
            'DisplayName', disp_name);
    end
    xlabel('RAAN (deg)');
    ylabel('pass ratio');
    title('Stage14 DG-only sensitivity: pass ratio vs RAAN');
    legend('Location', 'best');
    hold off;

    % ------------------------------------------------------------
    % 6) 图 2：D_G_mean vs RAAN
    % ------------------------------------------------------------
    fig_dgm = figure('Name', 'Stage14 D_G_mean vs RAAN', ...
        'NumberTitle', 'off', 'Visible', overrides.visible);
    hold on; grid on; box on;

    for it = 1:numel(tags)
        sub = detail_table(detail_table.tag == tags(it), :);
        sub = sortrows(sub, 'RAAN_deg');
        if isKey(pretty_names, char(tags(it)))
            disp_name = pretty_names(char(tags(it)));
        else
            disp_name = char(tags(it));
        end
        plot(sub.RAAN_deg, sub.D_G_mean, '-o', ...
            'LineWidth', 1.5, 'MarkerSize', 6, ...
            'DisplayName', disp_name);
    end
    xlabel('RAAN (deg)');
    ylabel('D_G mean');
    title('Stage14 DG-only sensitivity: D_G mean vs RAAN');
    legend('Location', 'best');
    hold off;

    % ------------------------------------------------------------
    % 7) 图 3：D_G_min vs RAAN
    % ------------------------------------------------------------
    fig_dgmin = figure('Name', 'Stage14 D_G_min vs RAAN', ...
        'NumberTitle', 'off', 'Visible', overrides.visible);
    hold on; grid on; box on;

    for it = 1:numel(tags)
        sub = detail_table(detail_table.tag == tags(it), :);
        sub = sortrows(sub, 'RAAN_deg');
        if isKey(pretty_names, char(tags(it)))
            disp_name = pretty_names(char(tags(it)));
        else
            disp_name = char(tags(it));
        end
        plot(sub.RAAN_deg, sub.D_G_min, '-o', ...
            'LineWidth', 1.5, 'MarkerSize', 6, ...
            'DisplayName', disp_name);
    end
    xlabel('RAAN (deg)');
    ylabel('D_G min');
    title('Stage14 DG-only sensitivity: D_G min vs RAAN');
    legend('Location', 'best');
    hold off;

    % ------------------------------------------------------------
    % 8) 保存图
    % ------------------------------------------------------------
    files = struct();
    files.fig_dir = fig_dir;
    files.pass_ratio_png = '';
    files.DG_mean_png = '';
    files.DG_min_png = '';

    if overrides.save_fig
        files.pass_ratio_png = fullfile(fig_dir, sprintf('stage14_pass_ratio_vs_raan_%s.png', ts));
        files.DG_mean_png = fullfile(fig_dir, sprintf('stage14_DG_mean_vs_raan_%s.png', ts));
        files.DG_min_png = fullfile(fig_dir, sprintf('stage14_DG_min_vs_raan_%s.png', ts));

        exportgraphics(fig_pass, files.pass_ratio_png, 'Resolution', 200);
        exportgraphics(fig_dgm, files.DG_mean_png, 'Resolution', 200);
        exportgraphics(fig_dgmin, files.DG_min_png, 'Resolution', 200);
    end

    % ------------------------------------------------------------
    % 9) 汇总输出
    % ------------------------------------------------------------
    out = struct();
    out.config_table = config_table;
    out.summary_table = summary_table;
    out.detail_table = detail_table;
    out.fig_pass_ratio = fig_pass;
    out.fig_DG_mean = fig_dgm;
    out.fig_DG_min = fig_dgmin;
    out.files = files;

    fprintf('\n=== Stage14.2B Plot Profiles ===\n');
    fprintf('figure dir        : %s\n', files.fig_dir);
    fprintf('pass_ratio png    : %s\n', files.pass_ratio_png);
    fprintf('D_G_mean png      : %s\n', files.DG_mean_png);
    fprintf('D_G_min png       : %s\n\n', files.DG_min_png);

    fprintf('--- summary_table ---\n');
    disp(summary_table);
end
