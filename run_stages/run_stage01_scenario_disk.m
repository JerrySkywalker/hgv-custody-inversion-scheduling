%% run_stage01_scenario_disk.m
% 一键运行 Stage01：保护盘场景与案例库构建
%
% 本脚本按顺序执行 Stage01 下的唯一入口。
%
% Stage01 步骤说明：
%   Step 1.1  scenario_disk
%             - 构建抽象保护盘场景（R_D、R_in 等）
%             - 可选地理锚点（cfg.geo.enable_geodetic_anchor）下生成 ENU/ECEF/ECI 入口点
%             - 生成 nominal / heading / critical 三类 casebank
%             - 输出 casebank、summary 及场景图
%
% 依赖：无（或先运行 Stage00 以初始化目录）
%
% 使用：在工程根目录下运行
%   run_stages/run_stage01_scenario_disk

function run_stage01_scenario_disk()
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    fprintf('[run_stages] === Stage01 一键运行 ===\n');

    out = stage01_scenario_disk();
    fprintf('[run_stages] Stage01 完成: %s\n', out.status);
end
