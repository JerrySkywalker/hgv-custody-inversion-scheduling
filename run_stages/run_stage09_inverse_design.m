%% run_stage09_inverse_design.m
% 一键运行 Stage09 全流程（扫描 + 作图）
%
% 当前推荐工作流：
%   1) 调试扫描：run_stage09_inverse_scan(...)
%   2) 调试作图：run_stage09_inverse_plot(...)
%   3) 完整联跑：run_stage09_inverse_design(...)
%
% 使用：
%   run_stage09_inverse_design()
%   run_stage09_inverse_design(cfg)
%   run_stage09_inverse_design(cfg, false)
%   run_stage09_inverse_design(cfg, true, opts)
%
% 关键 opts：
%   opts.stage09_plot_mode           = 'legacy10' | 'layered_suite'
%   opts.stage09_run_plot_after_scan = true/false
%   opts.stage09_enable_multih       = true/false
%   opts.stage09_enable_stack3d      = true/false

function out = run_stage09_inverse_design(cfg, interactive, opts)
    cfg_missing = (nargin < 1 || isempty(cfg));

    if nargin < 1
        cfg = [];
    end
    if nargin < 2
        interactive = (nargin == 0);
    end
    if nargin < 3
        opts = struct();
    end

    fprintf('[run_stages] === Stage09 全流程入口（scan + plot）===\n');

    out = struct();

    % 只在入口层交互一次
    if cfg_missing
        evalc('startup(''force'', false);');
        cfg = default_params();
    end
    [cfg, opts] = rs_cli_configure('stage09', cfg, interactive, opts);
    [cfg, ~] = rs_apply_parallel_policy('stage09', cfg, opts);

    if ~isfield(opts, 'stage09_plot_mode') || isempty(opts.stage09_plot_mode)
        opts.stage09_plot_mode = 'layered_suite';
    end

    fprintf('[run_stages] plot_mode : %s\n', string(opts.stage09_plot_mode));

    out.scan = run_stage09_inverse_scan(cfg, false, opts);

    run_plot = true;
    if isfield(opts, 'stage09_run_plot_after_scan')
        run_plot = logical(opts.stage09_run_plot_after_scan);
    end

    if run_plot
        out.plot = run_stage09_inverse_plot(out.scan.cfg, false, opts);
    else
        out.plot = struct();
    end

    fprintf('[run_stages] === Stage09 全流程完成 ===\n');
end
