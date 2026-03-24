%% run_stage08_window_selection.m
% 一键运行 Stage08：时间窗扫描与最终窗选型
%
% 本脚本按顺序执行 Stage08 下各步骤：定义窗范围 -> 代表案例扫描 -> 案例库统计 -> 小网格搜索 -> 边界窗敏感度 -> 最终汇总与推荐。
%
% Stage08 步骤说明：
%   Step 8.1  define_window_scope (Stage08.1)
%             - 加载 Stage07 参考 Walker、选例、论文范围与风险图，构建 Tw 网格与代表案例表
%   Step 8.2  scan_representative_cases (Stage08.2)
%             - 对代表案例在 Tw 网格上扫描，得到响应与可行性汇总
%   Step 8.3  scan_casebank_stats (Stage08.3)
%             - 对 Stage08.1 冻结的完整 casebank 在 Tw 上扫描，输出族级稳定性与排名表
%   Step 8.4  scan_smallgrid_search (Stage08.4)
%             - 在参考 Walker 邻域做小网格 (h,i,P,T) 搜索，评估不同 Tw 下的可行配置
%   Step 8.5  boundary_window_sensitivity (Stage08.4c)
%             - 边界时间窗敏感度分析，输出 boundary_N_min、boundary_feasible_ratio 等
%   Step 8.6  finalize_window_selection (Stage08.5)
%             - 汇总 08.2/08.3(可选)/08.4/08.4c，生成最终窗推荐表、summary CSV 与论文用图
%
% 依赖：需先完成 Stage07（select_reference_walker、select_critical_examples 等）
%
% 使用：在工程根目录下运行
%   run_stages/run_stage08_window_selection

function out = run_stage08_window_selection(cfg, interactive, opts)
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

    [cfg, opts] = rs_cli_configure('stage08', cfg, interactive, opts);
    [cfg, ~] = rs_apply_parallel_policy('stage08', cfg, opts);

    fprintf('[run_stages] === Stage08 一键运行 ===\n');

    % Step 8.1
    fprintf('[run_stages] Step 8.1  define_window_scope ...\n');
    out.out1 = stage08_define_window_scope(cfg);
    fprintf('[run_stages] Step 8.1 完成\n');

    % Step 8.2
    fprintf('[run_stages] Step 8.2  scan_representative_cases ...\n');
    out.out2 = stage08_scan_representative_cases(cfg);
    fprintf('[run_stages] Step 8.2 完成\n');

    % Step 8.3
    fprintf('[run_stages] Step 8.3  scan_casebank_stats ...\n');
    out.out3 = stage08_scan_casebank_stats(cfg);
    fprintf('[run_stages] Step 8.3 完成\n');

    % Step 8.4
    fprintf('[run_stages] Step 8.4  scan_smallgrid_search ...\n');
    out.out4 = stage08_scan_smallgrid_search(cfg);
    fprintf('[run_stages] Step 8.4 完成\n');

    % Step 8.5
    fprintf('[run_stages] Step 8.5  boundary_window_sensitivity ...\n');
    out.out5 = stage08_boundary_window_sensitivity(cfg);
    fprintf('[run_stages] Step 8.5 完成\n');

    % Step 8.6
    fprintf('[run_stages] Step 8.6  finalize_window_selection ...\n');
    out.out6 = stage08_finalize_window_selection(cfg);
    fprintf('[run_stages] Step 8.6 完成\n');

    fprintf('[run_stages] Stage08 全部完成\n');
end
