%% run_all_stages.m
% 一键按顺序运行 Stage00 至 Stage08 全流程
%
% 各 Stage 含义见 README 或各 run_stageXX_*.m 头部注释。
% 每步依赖前序 Stage 的 cache，请勿跳过。
%
% 使用：在工程根目录下运行
%   run_stages/run_all_stages

function run_all_stages()
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end
    startup();

    fprintf('[run_stages] ========== 全流程 Stage00 -> Stage08 ==========\n');

    run_stage00_bootstrap();
    run_stage01_scenario_disk();
    run_stage02_hgv_nominal();
    run_stage03_visibility_pipeline();
    run_stage04_window_worstcase();
    run_stage05_nominal_walker();
    run_stage06_heading_walker();
    run_stage07_critical_geometry();
    run_stage08_window_selection();

    fprintf('[run_stages] ========== 全流程完成 ==========\n');
end
