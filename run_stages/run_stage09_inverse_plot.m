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
%   run_stage09_inverse_plot('full_main')
%   run_stage09_inverse_plot('validation_small')
%   run_stage09_inverse_plot('custom', cfg)
%
% 说明：
%   若 out9_4 / out9_5 已在工作区中，也可直接调用：
%       stage09_plot_inverse_design_results(out9_4, out9_5, cfg)

function out = run_stage09_inverse_plot(scheme_type, cfg)
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
    cfg = stage09_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage09 作图入口 ===\n');
    fprintf('[run_stages] scheme_type : %s\n', cfg.stage09.scheme_type);
    fprintf('[run_stages] run_tag     : %s\n', cfg.stage09.run_tag);

    out = stage09_plot_inverse_design_results([], [], cfg);

    fprintf('[run_stages] === Stage09 作图完成 ===\n');
end