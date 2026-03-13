%% run_stage09_inverse_design.m
% 一键运行 Stage09：鲁棒 D 系列闭合、可行域构建、最小规模边界提取与结果导图
%
% 本脚本按顺序执行 Stage09 下各步骤：
%   Step 9.1  prepare_task_spec
%             - 冻结 Stage09 的任务输入、标准窗口 Tw_star、正式门槛与搜索域
%   Step 9.2  validate_window_kernel
%             - 验证 Wr -> DG/DA 指标核是否数值正常（可选）
%   Step 9.3  validate_single_design
%             - 对单一候选 Walker 构型做完整 casebank 的鲁棒判定（可选）
%   Step 9.4  build_feasible_domain
%             - 在 Stage09 搜索域上构造可行参数域 Theta_feas
%   Step 9.5  extract_minimum_boundary
%             - 从可行域中提取最小规模边界 N_min^rob 及参数范围摘要
%   Step 9.6  plot_inverse_design_results
%             - 导出可行域图、主导失效分区图、最小规模边界图等
%
% 支持三类 scheme_type：
%   'validation_small' : 当前已跑通的小参数验证方案
%   'full_main'        : 正式大参数主扫描方案
%   'custom'           : 完全手工控制（需在 cfg.stage09 中自行指定）
%
% 使用方式：
%   run_stages/run_stage09_inverse_design
%   run_stage09_inverse_design()
%   run_stage09_inverse_design('validation_small')
%   run_stage09_inverse_design('full_main')
%
% 自定义方式：
%   cfg = default_params();
%   cfg.stage09.scheme_type = 'custom';
%   cfg.stage09.search_domain.h_grid_km = 500:100:1000;
%   ...
%   run_stage09_inverse_design('custom', cfg)
%
% 依赖：
%   需先完成 Stage08（至少完成 Stage08.5，保证 Tw_star 可继承）
%
% 说明：
%   对于正式大参数扫描，建议 use_early_stop = false，
%   以保证 DG/DA/DT 的鲁棒值来自完整 casebank。

function out = run_stage09_inverse_design(scheme_type, cfg)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end
    startup();

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end

    if nargin < 1 || isempty(scheme_type)
        if isfield(cfg, 'stage09') && isfield(cfg.stage09, 'scheme_type')
            scheme_type = cfg.stage09.scheme_type;
        else
            scheme_type = 'validation_small';
        end
    end

    cfg.stage09.scheme_type = char(string(scheme_type));

    % 推荐正式扫描关闭 early-stop；若用户已明确设置，则尊重用户
    if ~isfield(cfg.stage09, 'use_early_stop') || isempty(cfg.stage09.use_early_stop)
        cfg.stage09.use_early_stop = false;
    end

    cfg = stage09_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage09 一键运行 ===\n');
    fprintf('[run_stages] scheme_type   : %s\n', cfg.stage09.scheme_type);
    fprintf('[run_stages] run_tag       : %s\n', cfg.stage09.run_tag);
    fprintf('[run_stages] casebank_mode : %s\n', cfg.stage09.casebank_mode);
    fprintf('[run_stages] h grid [km]   : %s\n', mat2str(cfg.stage09.search_domain.h_grid_km));
    fprintf('[run_stages] i grid [deg]  : %s\n', mat2str(cfg.stage09.search_domain.i_grid_deg));
    fprintf('[run_stages] P grid        : %s\n', mat2str(cfg.stage09.search_domain.P_grid));
    fprintf('[run_stages] T grid        : %s\n', mat2str(cfg.stage09.search_domain.T_grid));

    out = struct();

    % Step 9.1
    fprintf('[run_stages] Step 9.1  prepare_task_spec ...\n');
    out.out9_1 = stage09_prepare_task_spec(cfg);
    fprintf('[run_stages] Step 9.1 完成\n');

    % Step 9.2（可选验证）
    fprintf('[run_stages] Step 9.2  validate_window_kernel ...\n');
    out.out9_2 = stage09_validate_window_kernel(cfg);
    fprintf('[run_stages] Step 9.2 完成\n');

    % Step 9.3（可选验证）
    fprintf('[run_stages] Step 9.3  validate_single_design ...\n');
    out.out9_3 = stage09_validate_single_design(cfg);
    fprintf('[run_stages] Step 9.3 完成\n');

    % Step 9.4
    fprintf('[run_stages] Step 9.4  build_feasible_domain ...\n');
    out.out9_4 = stage09_build_feasible_domain(cfg);
    fprintf('[run_stages] Step 9.4 完成\n');

    % Step 9.5
    fprintf('[run_stages] Step 9.5  extract_minimum_boundary ...\n');
    out.out9_5 = stage09_extract_minimum_boundary(out.out9_4, cfg);
    fprintf('[run_stages] Step 9.5 完成\n');

    % Step 9.6
    fprintf('[run_stages] Step 9.6  plot_inverse_design_results ...\n');
    out.out9_6 = stage09_plot_inverse_design_results(out.out9_4, out.out9_5, cfg);
    fprintf('[run_stages] Step 9.6 完成\n');

    fprintf('[run_stages] === Stage09 全部完成 ===\n');
end