%% run_stage06_heading_walker.m
% 一键运行 Stage06：航向族 Walker 搜索与对比
%
% 本脚本按顺序执行 Stage06 下各步骤：定义航向范围 -> 构建航向族 -> 搜索 -> 与 Stage05 对比 -> 绘图。
%
% Stage06 步骤说明：
%   Step 6.1  define_heading_scope
%             - 定义当前 run_tag 下的航向偏移集合与搜索范围（继承 Stage05 网格等）
%   Step 6.2  build_heading_family_physical_demo
%             - 构建航向族物理演示（一族多航向的轨迹/可见性等）
%   Step 6.3  heading_walker_search
%             - 在航向族上做 Walker (i,P,T) 搜索，得到可行解与最优配置
%   Step 6.4  compare_with_stage05
%             - 与 Stage05 标称结果对比，汇总可行数、最优 Ns 等
%   Step 6.5  plot_heading_results
%             - 绘制航向族搜索结果图与对比图
%
% 依赖：需先完成 Stage05（nominal_walker_search 至少跑完）
%
% 使用：在工程根目录下运行
%   run_stages/run_stage06_heading_walker
%
% 说明：若需多组航向批量运行，请直接调用 stage06_batch_heading_runs(cfg)，并在 cfg.stage06.batch 中配置 run_tags 与 heading_offset_sets。

function out = run_stage06_heading_walker(cfg, interactive)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end

    [cfg, ~] = rs_cli_configure('stage06', cfg, interactive);

    fprintf('[run_stages] === Stage06 一键运行 ===\n');

    % Step 6.1: 定义航向范围
    fprintf('[run_stages] Step 6.1  define_heading_scope ...\n');
    out.out1 = stage06_define_heading_scope(cfg);
    fprintf('[run_stages] Step 6.1 完成\n');

    % Step 6.2: 构建航向族（物理演示）
    fprintf('[run_stages] Step 6.2  build_heading_family_physical_demo ...\n');
    out.out2 = stage06_build_heading_family_physical_demo(cfg);
    fprintf('[run_stages] Step 6.2 完成\n');

    % Step 6.3: 航向族 Walker 搜索
    fprintf('[run_stages] Step 6.3  heading_walker_search ...\n');
    out.out3 = stage06_heading_walker_search(cfg);
    fprintf('[run_stages] Step 6.3 完成\n');

    % Step 6.4: 与 Stage05 对比
    fprintf('[run_stages] Step 6.4  compare_with_stage05 ...\n');
    out.out4 = stage06_compare_with_stage05(cfg);
    fprintf('[run_stages] Step 6.4 完成\n');

    % Step 6.5: 绘制航向结果
    fprintf('[run_stages] Step 6.5  plot_heading_results ...\n');
    out.out5 = stage06_plot_heading_results(cfg);
    fprintf('[run_stages] Step 6.5 完成\n');

    fprintf('[run_stages] Stage06 全部完成\n');
end
