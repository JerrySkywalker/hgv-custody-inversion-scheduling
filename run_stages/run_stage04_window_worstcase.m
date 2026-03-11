%% run_stage04_window_worstcase.m
% 一键运行 Stage04：时间窗最坏情况与信息矩阵
%
% 本脚本按顺序执行 Stage04 下的唯一入口。
%
% Stage04 步骤说明：
%   Step 4.1  window_worstcase
%             - 从 Stage03 最新 cache 加载 satbank、visbank
%             - 对各族构建滑动时间窗下的信息矩阵，扫描最坏时间窗
%             - 校准 gamma_req，并生成谱级与 margin 级统计
%             - 输出 winbank、gamma_meta 及各类汇总与图形
%
% 依赖：需先运行 Stage03（stage03_visibility_pipeline）
%
% 使用：在工程根目录下运行
%   run_stages/run_stage04_window_worstcase

function run_stage04_window_worstcase()
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    fprintf('[run_stages] === Stage04 一键运行 ===\n');

    out = stage04_window_worstcase();
    fprintf('[run_stages] Stage04 完成\n');
end
