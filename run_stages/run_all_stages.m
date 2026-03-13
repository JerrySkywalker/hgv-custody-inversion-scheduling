%% run_all_stages.m
% 一键按顺序运行 Stage00 至 Stage09 全流程
%
% 各 Stage 含义见 README 或各 run_stageXX_*.m 头部注释。
% 每步依赖前序 Stage 的 cache，请勿跳过。
%
% 使用：在工程根目录下运行
%   run_stages/run_all_stages
%   run_all_stages()
%   run_all_stages(true, 'validation_small')
%   run_all_stages(true, 'full_main')
%
% 输入参数：
%   run_stage09         : 是否在 Stage08 之后继续运行 Stage09（默认 true）
%   stage09_scheme_type : 'validation_small' / 'full_main' / 'custom'
%
% 说明：
%   若 stage09_scheme_type = 'custom'，建议不要直接用本函数，
%   而是在外部先构造 cfg，再调用 run_stage09_inverse_design('custom', cfg)。

function run_all_stages(run_stage09, stage09_scheme_type)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end
    startup();

    if nargin < 1 || isempty(run_stage09)
        run_stage09 = true;
    end
    if nargin < 2 || isempty(stage09_scheme_type)
        stage09_scheme_type = 'validation_small';
    end

    fprintf('[run_stages] ========== 全流程 Stage00 -> Stage09 ==========\n');

    run_stage00_bootstrap();
    run_stage01_scenario_disk();
    run_stage02_hgv_nominal();
    run_stage03_visibility_pipeline();
    run_stage04_window_worstcase();
    run_stage05_nominal_walker();
    run_stage06_heading_walker();
    run_stage07_critical_geometry();
    run_stage08_window_selection();

    if run_stage09
        run_stage09_inverse_design(stage09_scheme_type);
    end

    fprintf('[run_stages] ========== 全流程完成 ==========\n');
end