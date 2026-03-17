function out = stage12C_inverse_slice_packager(pool_or_cfg, slice_type, overrides)
%STAGE12C_INVERSE_SLICE_PACKAGER Package thesis slice views from the unified Milestone B truth pool.

startup();

if nargin < 1 || isempty(pool_or_cfg)
    pool_or_cfg = milestone_common_defaults();
end
if nargin < 2 || isempty(slice_type)
    slice_type = 'hi';
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

[pool, meta] = local_resolve_pool(pool_or_cfg, overrides);
[axis_labels, slice_name, view_anchor] = local_slice_config(pool, slice_type);
full_theta_table = pool.full_theta_table_joint;
feasible_theta_table = pool.feasible_theta_table_joint;
view_table = build_feasible_domain_views(full_theta_table, feasible_theta_table, view_anchor, slice_type);

summary = struct();
summary.num_grid_points = height(view_table);
summary.num_feasible_points = sum(view_table.is_feasible);
summary.feasible_ratio = local_safe_ratio(summary.num_feasible_points, summary.num_grid_points);
summary.anchor = view_anchor;

out = struct();
out.cfg = pool.cfg;
out.pool_summary = pool.summary;
out.slice_name = string(slice_name);
out.axis_labels = axis_labels;
out.overrides = meta;
out.full_theta_table = full_theta_table;
out.feasible_theta_table = feasible_theta_table;
out.view_anchor = view_anchor;
out.view_table = view_table;
out.summary_table = table(string(slice_name), summary.num_grid_points, summary.num_feasible_points, summary.feasible_ratio, ...
    'VariableNames', {'slice_name', 'num_grid_points', 'num_feasible_points', 'feasible_ratio'});
out.fail_partition_table = local_view_fail_partition(view_table);
out.summary = summary;
out.files = struct();
end

function [pool, meta] = local_resolve_pool(pool_or_cfg, overrides)
if isstruct(pool_or_cfg) && isfield(pool_or_cfg, 'design_pool_table') && isfield(pool_or_cfg, 'full_theta_table_joint')
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

function [axis_labels, slice_name, view_anchor] = local_slice_config(pool, slice_type)
switch lower(char(string(slice_type)))
    case 'hi'
        axis_labels = {'h_km', 'i_deg'};
        slice_name = 'hi';
        view_anchor = pool.slice_anchor_hi;
    case 'pt'
        axis_labels = {'P', 'T'};
        slice_name = 'PT';
        view_anchor = pool.slice_anchor_pt;
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

function T = local_view_fail_partition(view_table)
T = table();
if isempty(view_table) || ~ismember('dominant_fail_tag', view_table.Properties.VariableNames)
    return;
end
[tags, ~, ic] = unique(string(view_table.dominant_fail_tag));
counts = accumarray(ic, 1);
T = table(tags, counts, 'VariableNames', {'dominant_fail_tag', 'count'});
T = sortrows(T, 'count', 'descend');
end
