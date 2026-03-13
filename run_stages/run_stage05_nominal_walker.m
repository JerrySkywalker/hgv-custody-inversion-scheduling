%% run_stage05_nominal_walker.m
% 一键运行 Stage05：标称族 Walker 静态搜索与后处理
%
% 本脚本按顺序执行 Stage05 下所有入口：搜索 -> 绘图 -> Pareto 分析。
%
% Stage05 步骤说明：
%   Step 5.1  nominal_walker_search (Stage05.2b)
%             - 从 Stage04 继承 gamma_req，在 (i, P, T) 网格上做标称族 Walker 静态搜索（固定 h）
%             - 使用 parfeval/fetchNext 并行与早停，输出 grid、feasible_grid、summary
%   Step 5.2  plot_nominal_results (Stage05.3)
%             - 读取 Stage05.2b cache，生成最优可行表、可行排序表、倾角前沿表
%             - 生成可行 Ns-D_G 散点图、倾角前沿图、min-Ns 与 best-D_G 热力图
%   Step 5.3  analyze_pareto_transition (Stage05.4)
%             - 全局 Pareto 前沿 (Ns, D_G_min)、倾角维度的阈值/转换诊断
%             - 输出表格与图形供论文使用
%
% 依赖：需先运行 Stage04（stage04_window_worstcase）
%
% 使用：在工程根目录下运行
%   run_stages/run_stage05_nominal_walker

function out = run_stage05_nominal_walker(cfg, interactive)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end

    [cfg, ~] = rs_cli_configure('stage05', cfg, interactive);

    fprintf('[run_stages] === Stage05 一键运行 ===\n');

    % Step 5.1: 标称 Walker 网格搜索
    fprintf('[run_stages] Step 5.1  nominal_walker_search ...\n');
    out.out1 = stage05_nominal_walker_search(cfg);
    fprintf('[run_stages] Step 5.1 完成\n');

    % Step 5.2: 结果可视化
    fprintf('[run_stages] Step 5.2  plot_nominal_results ...\n');
    out.out2 = stage05_plot_nominal_results(cfg);
    fprintf('[run_stages] Step 5.2 完成\n');

    % Step 5.3: Pareto 与转换分析
    fprintf('[run_stages] Step 5.3  analyze_pareto_transition ...\n');
    out.out3 = stage05_analyze_pareto_transition();
    fprintf('[run_stages] Step 5.3 完成\n');

    fprintf('[run_stages] Stage05 全部完成\n');
end
