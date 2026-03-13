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
%   run_stage09_inverse_design('validation_small')
%   run_stage09_inverse_design('full_main')
%   run_stage09_inverse_design('custom', cfg)

function out = run_stage09_inverse_design(scheme_type, cfg)
    if nargin < 2
        cfg = [];
    end
    if nargin < 1
        scheme_type = [];
    end

    fprintf('[run_stages] === Stage09 全流程入口（scan + plot）===\n');

    out = struct();
    out.scan = run_stage09_inverse_scan(scheme_type, cfg);
    out.plot = run_stage09_inverse_plot(scheme_type, cfg);

    fprintf('[run_stages] === Stage09 全流程完成 ===\n');
end