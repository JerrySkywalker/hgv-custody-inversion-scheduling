%% run_all_stages.m
% 一键按顺序运行 Stage00 至 Stage09 全流程
%
% 使用：
%   run_all_stages()
%   run_all_stages(true, 'validation_small', true)
%   run_all_stages(true, 'full_main', false)
%
% 输入参数：
%   run_stage09         : 是否在 Stage08 后继续运行 Stage09（默认 true）
%   stage09_scheme_type : 'validation_small' / 'full_main' / 'custom'
%   run_stage09_plot    : Stage09 扫描完成后是否立即作图（默认 true）
%
% 说明：
%   如果只想做正式大参数扫描，不想每次都重画图：
%       run_all_stages(true, 'full_main', false)

function run_all_stages(run_stage09, stage09_scheme_type, run_stage09_plot)
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
    if nargin < 3 || isempty(run_stage09_plot)
        run_stage09_plot = true;
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
        run_stage09_inverse_scan(stage09_scheme_type);
        if run_stage09_plot
            run_stage09_inverse_plot(stage09_scheme_type);
        end
    end

    fprintf('[run_stages] ========== 全流程完成 ==========\n');
end