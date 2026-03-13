%% run_stage07_critical_geometry.m
% 一键运行 Stage07：临界几何与参考 Walker、论文图
%
% 本脚本按顺序执行 Stage07 下各步骤：选参考 Walker -> 定义临界范围 -> 风险图 -> 选例 -> 论文范围与绘图。
%
% Stage07 步骤说明：
%   Step 7.1  select_reference_walker (Stage07.1)
%             - 从 Stage05/06 结果中选取参考 Walker 配置，输出排序与 summary
%   Step 7.2  define_critical_scope_refwalker (Stage07.2)
%             - 相对该参考 Walker 定义 C1/C2 临界几何范围与航向扫描设置
%   Step 7.3  scan_heading_risk_map (Stage07.3)
%             - 扫描航向-风险图，得到各入口的 D_G、覆盖率等风险汇总
%   Step 7.4  select_critical_examples (Stage07.4)
%             - 从风险图中选取 nominal/C1/C2 代表样本，供后续绘图与 Stage08 使用
%   Step 7.5  define_paper_plot_scope (Stage07.6.1)
%             - 定义论文用绘图子集（入口与案例筛选）
%   Step 7.6  plot_paper_subset
%             - 绘制论文子集图（D_G、lambda 等对比）
%   Step 7.7  plot_critical_geometry
%             - 绘制临界几何对比图、曲线与 cov vs D_G 散点
%   Step 7.8  write_paper_figure_notes
%             - 输出论文用图注与 summary 表格
%
% 依赖：需先完成 Stage05、Stage06（至少完成 heading 搜索与 compare）
%
% 使用：在工程根目录下运行
%   run_stages/run_stage07_critical_geometry

function out = run_stage07_critical_geometry(cfg, interactive, opts)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    [cfg, opts] = rs_cli_configure('stage07', cfg, interactive, opts);
    [cfg, ~] = rs_apply_parallel_policy('stage07', cfg, opts);

    fprintf('[run_stages] === Stage07 一键运行 ===\n');

    % Step 7.1
    fprintf('[run_stages] Step 7.1  select_reference_walker ...\n');
    out.out1 = stage07_select_reference_walker(cfg);
    fprintf('[run_stages] Step 7.1 完成\n');

    % Step 7.2
    fprintf('[run_stages] Step 7.2  define_critical_scope_refwalker ...\n');
    out.out2 = stage07_define_critical_scope_refwalker(cfg);
    fprintf('[run_stages] Step 7.2 完成\n');

    % Step 7.3
    fprintf('[run_stages] Step 7.3  scan_heading_risk_map ...\n');
    out.out3 = stage07_scan_heading_risk_map(cfg);
    fprintf('[run_stages] Step 7.3 完成\n');

    % Step 7.4
    fprintf('[run_stages] Step 7.4  select_critical_examples ...\n');
    out.out4 = stage07_select_critical_examples(cfg);
    fprintf('[run_stages] Step 7.4 完成\n');

    % Step 7.5
    fprintf('[run_stages] Step 7.5  define_paper_plot_scope ...\n');
    out.out5 = stage07_define_paper_plot_scope(cfg);
    fprintf('[run_stages] Step 7.5 完成\n');

    % Step 7.6
    fprintf('[run_stages] Step 7.6  plot_paper_subset ...\n');
    out.out6 = stage07_plot_paper_subset(cfg);
    fprintf('[run_stages] Step 7.6 完成\n');

    % Step 7.7
    fprintf('[run_stages] Step 7.7  plot_critical_geometry ...\n');
    out.out7 = stage07_plot_critical_geometry(cfg);
    fprintf('[run_stages] Step 7.7 完成\n');

    % Step 7.8
    fprintf('[run_stages] Step 7.8  write_paper_figure_notes ...\n');
    out.out8 = stage07_write_paper_figure_notes(cfg);
    fprintf('[run_stages] Step 7.8 完成\n');

    fprintf('[run_stages] Stage07 全部完成\n');
end
