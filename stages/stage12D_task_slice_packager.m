function out = stage12D_task_slice_packager(cfg, task_mode, overrides)
%STAGE12D_TASK_SLICE_PACKAGER Package task-side slices for Milestone B.

startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(task_mode)
    task_mode = 'nominal';
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

cfg = milestone_common_defaults(cfg);
cfg = stage09_prepare_cfg(cfg);
cfg.stage09.run_tag = sprintf('stage12D_%s', char(string(task_mode)));

cfg_stage = local_configure_task_slice(cfg, task_mode, overrides);
out_scan = stage09_build_feasible_domain(cfg_stage);

summary = struct();
summary.num_grid_points = height(out_scan.full_theta_table);
summary.num_feasible_points = height(out_scan.feasible_theta_table);
summary.feasible_ratio = local_safe_ratio(summary.num_feasible_points, summary.num_grid_points);

out = struct();
out.cfg = cfg_stage;
out.task_slice_id = string(task_mode);
out.overrides = overrides;
out.full_theta_table = local_normalize_theta_table(out_scan.full_theta_table);
out.feasible_theta_table = local_normalize_theta_table(out_scan.feasible_theta_table);
out.summary_table = out_scan.summary_table;
out.fail_partition_table = out_scan.fail_partition_table;
out.summary = summary;
out.metadata = struct('sensor_condition', string(cfg.milestones.slice_settings.sensor_condition));
out.files = out_scan.files;
end

function cfg_stage = local_configure_task_slice(cfg, task_mode, overrides)
cfg_stage = cfg;
slice_cfg = cfg.milestones.slice_settings;
theta = cfg.milestones.baseline_theta;
if isfield(overrides, 'slice_settings') && isstruct(overrides.slice_settings)
    slice_cfg = milestone_common_merge_structs(slice_cfg, overrides.slice_settings);
end
if isfield(overrides, 'theta') && isstruct(overrides.theta)
    theta = milestone_common_merge_structs(theta, overrides.theta);
end

cfg_stage.stage09.casebank_mode = 'custom';
cfg_stage.stage09.casebank_include_nominal = false;
cfg_stage.stage09.casebank_include_heading = false;
cfg_stage.stage09.casebank_include_critical = false;
cfg_stage.stage09.search_domain.h_grid_km = slice_cfg.h_km;
cfg_stage.stage09.search_domain.i_grid_deg = slice_cfg.i_deg;
cfg_stage.stage09.search_domain.P_grid = slice_cfg.P;
cfg_stage.stage09.search_domain.T_grid = slice_cfg.T;
cfg_stage.stage09.search_domain.F_fixed = theta.F;

switch lower(char(string(task_mode)))
    case 'nominal'
        cfg_stage.stage09.casebank_include_nominal = true;
    case 'heading'
        cfg_stage.stage09.casebank_include_heading = true;
        if isfield(slice_cfg, 'heading_subset_max') && ~isempty(slice_cfg.heading_subset_max)
            cfg_stage.stage09.casebank_heading_subset_max = slice_cfg.heading_subset_max;
        else
            cfg_stage.stage09.casebank_heading_subset_max = 10;
        end
    case 'critical'
        cfg_stage.stage09.casebank_include_critical = true;
    otherwise
        error('Unsupported task_mode: %s', string(task_mode));
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
