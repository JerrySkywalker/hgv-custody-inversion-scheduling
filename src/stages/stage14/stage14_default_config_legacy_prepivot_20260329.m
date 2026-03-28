function cfg = stage14_default_config_legacy_prepivot_20260329(base_cfg, overrides)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
%STAGE14_DEFAULT_CONFIG_LEGACY_PREPIVOT_20260329 Build Stage14 minimal default config.
%
% 设计原则：
% 1) 第一轮不改 default_params.m，避免大文件整体替换。
% 2) 尽量继承 Stage05 的搜索口径与阈值设置。
% 3) 仅新增 RAAN 扫描这一层自由度。
% 4) 当前版本先走串行最小骨架，后续再接并行与绘图。

if nargin < 1 || isempty(base_cfg)
    cfg = default_params();
else
    cfg = base_cfg;
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

existing_stage14 = struct();
if isfield(cfg, 'stage14') && isstruct(cfg.stage14)
    existing_stage14 = cfg.stage14;
end

cfg.stage14 = struct();
cfg.stage14.stage_name = 'stage14';
cfg.stage14.mode = 'openD_dg_sensitivity';
cfg.stage14.family_scope = 'nominal';
cfg.stage14.gamma_source = 'stage04_nominal_quantile';

% 继承 Stage05 搜索域
cfg.stage14.h_fixed_km = cfg.stage05.h_fixed_km;
cfg.stage14.F_fixed = cfg.stage05.F_fixed;
cfg.stage14.i_grid_deg = cfg.stage05.i_grid_deg;
cfg.stage14.P_grid = cfg.stage05.P_grid;
cfg.stage14.T_grid = cfg.stage05.T_grid;

% 新增：RAAN 扫描域
% 第一轮先用较粗步长，优先验证“曲线是否存在明显起伏/V字”
cfg.stage14.RAAN_scan_deg = 0:30:330;

% DG-only 阈值口径
cfg.stage14.require_pass_ratio = cfg.stage05.require_pass_ratio;
cfg.stage14.require_D_G_min = cfg.stage05.require_D_G_min;
cfg.stage14.rank_rule = cfg.stage05.rank_rule;

% 执行控制
cfg.stage14.use_parallel = false;
cfg.stage14.use_early_stop = cfg.stage05.use_early_stop;
cfg.stage14.hard_case_first = cfg.stage05.hard_case_first;
cfg.stage14.progress_every = 1;
cfg.stage14.case_limit = inf;

% 输出控制
cfg.stage14.save_cache = true;
cfg.stage14.save_table = true;
cfg.stage14.make_plot = false;

% 允许覆盖已有 stage14 字段
cfg.stage14 = local_merge_struct(cfg.stage14, existing_stage14);
cfg.stage14 = local_merge_struct(cfg.stage14, overrides);

% 兼容：保证向量为行向量，便于后续打印
cfg.stage14.i_grid_deg = reshape(cfg.stage14.i_grid_deg, 1, []);
cfg.stage14.P_grid = reshape(cfg.stage14.P_grid, 1, []);
cfg.stage14.T_grid = reshape(cfg.stage14.T_grid, 1, []);
cfg.stage14.RAAN_scan_deg = reshape(cfg.stage14.RAAN_scan_deg, 1, []);

end

function out = local_merge_struct(base, patch)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
out = base;
if nargin < 2 || isempty(patch) || ~isstruct(patch)
    return;
end

fn = fieldnames(patch);
for k = 1:numel(fn)
    key = fn{k};
    val = patch.(key);
    if isstruct(val) && isfield(out, key) && isstruct(out.(key))
        out.(key) = local_merge_struct(out.(key), val);
    else
        out.(key) = val;
    end
end
end

