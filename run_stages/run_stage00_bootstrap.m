%% run_stage00_bootstrap.m
% 一键运行 Stage00：项目引导与环境自检
%
% 本脚本按顺序执行 Stage00 下的唯一入口，用于验证工程可运行性。
%
% Stage00 步骤说明：
%   Step 0.1  bootstrap
%             - 调用 startup() 初始化路径与 results 目录
%             - 加载 default_params() 默认配置
%             - 固定随机种子，创建日志与 cache 目录
%             - 写入简单汇总并保存 cache，用于 CI/自检
%
% 使用：在 MATLAB 中将当前目录设为工程根目录后运行
%   cd('cpt4_disk_fresh')
%   run_stages/run_stage00_bootstrap

function out = run_stage00_bootstrap(cfg, interactive)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end

    [cfg, ~] = rs_cli_configure('stage00', cfg, interactive);

    fprintf('[run_stages] === Stage00 一键运行 ===\n');

    % Step 0.1: 引导与自检
    out = stage00_bootstrap(cfg);
    fprintf('[run_stages] Stage00 完成: %s\n', out.status);
end
