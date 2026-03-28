function out = run_stage14(cfg, interactive, overrides)
%RUN_STAGE14 Public entry for Stage14 OpenD / DG-only RAAN sensitivity scan.
%
% Stage14.1A 当前仅实现最小可运行骨架：
%   - 读取 Stage02 nominal family
%   - 读取 Stage04 gamma_req
%   - 在 (i, P, T, RAAN) 网格上做 DG-only 扫描
%   - 输出 grid / summary / cache / csv
%
% 本阶段暂不做：
%   - 画图
%   - 并行
%   - run_all_stages 集成
%   - Stage15 闭合指标

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
    addpath(fullfile(proj_root, 'run_stages'));
    addpath(fullfile(proj_root, 'src', 'stages', 'stage14'));
end
startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(interactive)
    interactive = (nargin == 0);
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

cfg = stage14_default_config(cfg, overrides);

fprintf('[run_stages] === Stage14 OpenD / DG-only RAAN sensitivity ===\n');
fprintf('[run_stages] mode              : %s\n', cfg.stage14.mode);
fprintf('[run_stages] family_scope      : %s\n', cfg.stage14.family_scope);
fprintf('[run_stages] h_fixed_km        : %.1f\n', cfg.stage14.h_fixed_km);
fprintf('[run_stages] i_grid_deg        : %s\n', mat2str(cfg.stage14.i_grid_deg));
fprintf('[run_stages] P_grid            : %s\n', mat2str(cfg.stage14.P_grid));
fprintf('[run_stages] T_grid            : %s\n', mat2str(cfg.stage14.T_grid));
fprintf('[run_stages] RAAN_scan_deg     : %s\n', mat2str(cfg.stage14.RAAN_scan_deg));
fprintf('[run_stages] require_D_G_min   : %.3f\n', cfg.stage14.require_D_G_min);
fprintf('[run_stages] require_pass_ratio: %.3f\n', cfg.stage14.require_pass_ratio);
fprintf('[run_stages] interactive       : %d\n', logical(interactive));

out = stage14_scan_openD_raan_grid(cfg);

fprintf('[run_stages] === Stage14 完成 ===\n');
end
