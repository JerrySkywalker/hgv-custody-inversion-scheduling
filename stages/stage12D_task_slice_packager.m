function out = stage12D_task_slice_packager(pool_or_cfg, task_mode, overrides)
%STAGE12D_TASK_SLICE_PACKAGER Package shared-pool task-family views for Milestone B.

startup();

if nargin < 1 || isempty(pool_or_cfg)
    pool_or_cfg = milestone_common_defaults();
end
if nargin < 2 || isempty(task_mode)
    task_mode = 'nominal';
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

[pool, meta] = local_resolve_pool(pool_or_cfg, overrides);
family_key = lower(char(string(task_mode)));
[full_theta_table, feasible_theta_table, family_eval] = local_pick_family_tables(pool, family_key);

summary = family_eval.summary;
summary.num_grid_points = height(full_theta_table);
summary.num_feasible_points = height(feasible_theta_table);
summary.casebank_breakdown = local_casebank_breakdown(family_eval.casebank);

out = struct();
out.cfg = family_eval.cfg;
out.task_slice_id = string(task_mode);
out.overrides = meta;
out.design_pool_table = pool.design_pool_table;
out.full_theta_table = full_theta_table;
out.feasible_theta_table = feasible_theta_table;
out.summary_table = table(string(task_mode), summary.num_total, summary.num_feasible, summary.feasible_ratio, ...
    summary.Ns_min_feasible, summary.best_joint_margin, summary.casebank_size, string(summary.config_signature), ...
    'VariableNames', {'family_name', 'num_total', 'num_feasible', 'feasible_ratio', 'Ns_min_feasible', 'best_joint_margin', 'casebank_size', 'config_signature'});
out.fail_partition_table = family_eval.fail_partition_table;
out.summary = summary;
out.metadata = struct('sensor_condition', string(pool.cfg.milestones.slice_settings.sensor_condition));
out.files = struct();
end

function [pool, meta] = local_resolve_pool(pool_or_cfg, overrides)
if isstruct(pool_or_cfg) && isfield(pool_or_cfg, 'design_pool_table') && isfield(pool_or_cfg, 'family_eval')
    pool = pool_or_cfg;
    meta = overrides;
else
    cfg = milestone_common_defaults(pool_or_cfg);
    meta = cfg.milestones.MB;
    if isstruct(overrides)
        meta = milestone_common_merge_structs(meta, overrides);
    end
    pool = stage12B_mb_design_pool(cfg, meta);
end
end

function [full_theta_table, feasible_theta_table, family_eval] = local_pick_family_tables(pool, family_key)
switch family_key
    case 'nominal'
        full_theta_table = pool.full_theta_table_nominal;
        feasible_theta_table = pool.feasible_theta_table_nominal;
    case 'heading'
        full_theta_table = pool.full_theta_table_heading;
        feasible_theta_table = pool.feasible_theta_table_heading;
    case 'critical'
        full_theta_table = pool.full_theta_table_critical;
        feasible_theta_table = pool.feasible_theta_table_critical;
    otherwise
        error('Unsupported task_mode: %s', string(family_key));
end
family_eval = pool.family_eval.(family_key);
end

function breakdown = local_casebank_breakdown(casebank)
breakdown = struct('nominal', 0, 'heading', 0, 'critical', 0);
if isempty(casebank)
    return;
end
for k = 1:numel(casebank)
    if isfield(casebank(k).case, 'family')
        family_name = lower(string(casebank(k).case.family));
        if isfield(breakdown, char(family_name))
            breakdown.(char(family_name)) = breakdown.(char(family_name)) + 1;
        end
    end
end
end
