%% run_stage02_hgv_nominal.m
% 一键运行 Stage02：HGV 标称轨迹生成
%
% 本脚本按顺序执行 Stage02 下的唯一入口。
%
% Stage02 步骤说明：
%   Step 2.1  hgv_nominal
%             - 从 Stage01 最新 cache 加载 casebank
%             - 对 nominal / heading / critical 三族分别进行 HGV 动力学传播（VTC 开环剖面）
%             - 输出轨迹库 trajbank（含 ENU/ECEF/ECI），以及 family/heading/critical 汇总与图形
%
% 依赖：需先运行 Stage01（stage01_scenario_disk）
%
% 使用：在工程根目录下运行
%   run_stages/run_stage02_hgv_nominal

function out = run_stage02_hgv_nominal(cfg, interactive, opts)
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

    [cfg, opts] = rs_cli_configure('stage02', cfg, interactive, opts);
    [cfg, stage_opts] = rs_apply_parallel_policy('stage02', cfg, opts);

    fprintf('[run_stages] === Stage02 一键运行 ===\n');

    out = stage02_hgv_nominal(cfg, stage_opts);
    fprintf('[run_stages] Stage02 完成\n');
end
