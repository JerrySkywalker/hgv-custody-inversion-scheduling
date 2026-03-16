function out = stage12C_inverse_slice_packager(cfg, slice_type, overrides)
%STAGE12C_INVERSE_SLICE_PACKAGER Package constellation-parameter slices for Milestone B.

startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(slice_type)
    slice_type = 'hi';
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

cfg = milestone_common_defaults(cfg);
cfg = stage09_prepare_cfg(cfg);
cfg.stage09.run_tag = sprintf('stage12C_%s', char(string(slice_type)));

[cfg_stage, axis_labels, slice_name] = local_configure_slice(cfg, slice_type, overrides);
out_scan = stage09_build_feasible_domain(cfg_stage);

summary = struct();
summary.num_grid_points = height(out_scan.full_theta_table);
summary.num_feasible_points = height(out_scan.feasible_theta_table);
summary.feasible_ratio = local_safe_ratio(summary.num_feasible_points, summary.num_grid_points);

out = struct();
out.cfg = cfg_stage;
out.slice_name = string(slice_name);
out.axis_labels = axis_labels;
out.overrides = overrides;
out.full_theta_table = local_normalize_theta_table(out_scan.full_theta_table);
out.feasible_theta_table = local_normalize_theta_table(out_scan.feasible_theta_table);
out.summary_table = out_scan.summary_table;
out.fail_partition_table = out_scan.fail_partition_table;
out.summary = summary;
out.files = out_scan.files;
end

function [cfg_stage, axis_labels, slice_name] = local_configure_slice(cfg, slice_type, overrides)
cfg_stage = cfg;
theta = cfg.milestones.baseline_theta;
slice_cfg = cfg.milestones.slice_settings;
if isfield(overrides, 'theta') && isstruct(overrides.theta)
    theta = milestone_common_merge_structs(theta, overrides.theta);
end
if isfield(overrides, 'slice_settings') && isstruct(overrides.slice_settings)
    slice_cfg = milestone_common_merge_structs(slice_cfg, overrides.slice_settings);
end

switch lower(char(string(slice_type)))
    case 'hi'
        cfg_stage.stage09.search_domain.h_grid_km = slice_cfg.h_km;
        cfg_stage.stage09.search_domain.i_grid_deg = slice_cfg.i_deg;
        cfg_stage.stage09.search_domain.P_grid = theta.P;
        cfg_stage.stage09.search_domain.T_grid = theta.T;
        cfg_stage.stage09.search_domain.F_fixed = theta.F;
        axis_labels = {'h_km', 'i_deg'};
        slice_name = 'hi';
    case 'pt'
        cfg_stage.stage09.search_domain.h_grid_km = theta.h_km;
        cfg_stage.stage09.search_domain.i_grid_deg = theta.i_deg;
        cfg_stage.stage09.search_domain.P_grid = slice_cfg.P;
        cfg_stage.stage09.search_domain.T_grid = slice_cfg.T;
        cfg_stage.stage09.search_domain.F_fixed = theta.F;
        axis_labels = {'P', 'T'};
        slice_name = 'PT';
    otherwise
        error('Unsupported slice_type: %s', string(slice_type));
end
end

function ratio = local_safe_ratio(a, b)
if b <= 0
    ratio = 0;
else
    ratio = a / b;
end
end

function T = local_normalize_theta_table(T)
if isempty(T)
    return;
end
T.DG_worst = T.DG_rob;
T.DA_worst = T.DA_rob;
T.DT_bar_worst = T.DT_bar_rob;
T.DT_worst = T.DT_rob;
T.feasible_flag = T.joint_feasible;
end
