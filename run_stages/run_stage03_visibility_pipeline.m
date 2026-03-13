%% run_stage03_visibility_pipeline.m
% 一键运行 Stage03：可见性管线（单层 Walker + 可见性矩阵）
%
% 本脚本按顺序执行 Stage03 下的唯一入口。
%
% Stage03 步骤说明：
%   Step 3.1  visibility_pipeline
%             - 从 Stage02 最新 cache 加载 trajbank
%             - 构建单层 Walker 基线星座并生成公共时间网格
%             - 对 nominal/heading/critical 各族计算可见性矩阵（基于 Stage02 的 ECI 轨迹）
%             - 输出 satbank、visbank 及汇总
%
% 依赖：需先运行 Stage02（stage02_hgv_nominal）
%
% 使用：在工程根目录下运行
%   run_stages/run_stage03_visibility_pipeline

function out = run_stage03_visibility_pipeline(cfg, interactive)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end

    [cfg, ~] = rs_cli_configure('stage03', cfg, interactive);

    fprintf('[run_stages] === Stage03 一键运行 ===\n');

    out = stage03_visibility_pipeline(cfg);
    fprintf('[run_stages] Stage03 完成\n');
end
