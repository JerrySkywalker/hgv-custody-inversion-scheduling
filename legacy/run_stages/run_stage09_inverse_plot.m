%% run_stage09_inverse_plot.m
% 一键运行 Stage09 作图部分：
%   Step 9.6  plot_inverse_design_results
%
% 用途：
%   - 在不重跑参数扫描的情况下反复重绘论文图
%   - 默认自动加载最新的 Stage09.4 / Stage09.5 cache
%
% 使用：
%   run_stage09_inverse_plot()
%   run_stage09_inverse_plot(cfg)
%   run_stage09_inverse_plot(cfg, false)

function out = run_stage09_inverse_plot(cfg, interactive, opts)
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

    [cfg, opts] = rs_cli_configure('stage09', cfg, interactive, opts);
    [cfg, ~] = rs_apply_parallel_policy('stage09', cfg, opts);
    cfg = stage09_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage09 作图入口 ===\n');
    fprintf('[run_stages] scheme_type : %s\n', cfg.stage09.scheme_type);
    fprintf('[run_stages] run_tag     : %s\n', cfg.stage09.run_tag);

    out = stage09_plot_inverse_design_results([], [], cfg);

    fprintf('[run_stages] === Stage09 作图完成 ===\n');
end
