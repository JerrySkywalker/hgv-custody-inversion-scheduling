%% run_stage09_inverse_scan.m
% 一键运行 Stage09 扫描部分（不作图）：
%   Step 9.1  prepare_task_spec
%   Step 9.4  build_feasible_domain
%   Step 9.5  extract_minimum_boundary
%
% 用途：
%   - 正式大参数扫描
%   - 调试参数域与边界提取
%   - 避免每次扫描后都重画图
%
% 使用：
%   run_stage09_inverse_scan()
%   run_stage09_inverse_scan(cfg)
%   run_stage09_inverse_scan(cfg, false)
%   run_stage09_inverse_scan(cfg, true, opts)

function out = run_stage09_inverse_scan(cfg, interactive, opts)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end
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

    % CLI 交互配置
    [cfg, opts] = rs_cli_configure('stage09', cfg, interactive, opts);

    % Stage09 正式建议：除非用户明确设置，否则关闭 early-stop
    if ~isfield(cfg.stage09, 'use_early_stop') || isempty(cfg.stage09.use_early_stop)
        cfg.stage09.use_early_stop = false;
    end

    cfg = stage09_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage09 扫描入口 ===\n');
    fprintf('[run_stages] scheme_type   : %s\n', cfg.stage09.scheme_type);
    fprintf('[run_stages] run_tag       : %s\n', cfg.stage09.run_tag);
    fprintf('[run_stages] casebank_mode : %s\n', cfg.stage09.casebank_mode);
    fprintf('[run_stages] h grid [km]   : %s\n', mat2str(cfg.stage09.search_domain.h_grid_km));
    fprintf('[run_stages] i grid [deg]  : %s\n', mat2str(cfg.stage09.search_domain.i_grid_deg));
    fprintf('[run_stages] P grid        : %s\n', mat2str(cfg.stage09.search_domain.P_grid));
    fprintf('[run_stages] T grid        : %s\n', mat2str(cfg.stage09.search_domain.T_grid));

    out = struct();
    out.cfg = cfg;
    out.opts = opts;

    fprintf('[run_stages] Step 9.1  prepare_task_spec ...\n');
    out.out9_1 = stage09_prepare_task_spec(cfg);
    fprintf('[run_stages] Step 9.1 完成\n');

    if isfield(opts, 'stage09_run_validate_kernel') && opts.stage09_run_validate_kernel
        fprintf('[run_stages] Step 9.2  validate_window_kernel ...\n');
        out.out9_2 = stage09_validate_window_kernel(cfg);
        fprintf('[run_stages] Step 9.2 完成\n');
    end

    if isfield(opts, 'stage09_run_validate_single') && opts.stage09_run_validate_single
        fprintf('[run_stages] Step 9.3  validate_single_design ...\n');
        out.out9_3 = stage09_validate_single_design(cfg);
        fprintf('[run_stages] Step 9.3 完成\n');
    end

    fprintf('[run_stages] Step 9.4  build_feasible_domain ...\n');
    out.out9_4 = stage09_build_feasible_domain(cfg);
    fprintf('[run_stages] Step 9.4 完成\n');

    fprintf('[run_stages] Step 9.5  extract_minimum_boundary ...\n');
    out.out9_5 = stage09_extract_minimum_boundary(out.out9_4, cfg);
    fprintf('[run_stages] Step 9.5 完成\n');

    fprintf('[run_stages] === Stage09 扫描部分完成 ===\n');
end