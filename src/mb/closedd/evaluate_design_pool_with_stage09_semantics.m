function out = evaluate_design_pool_with_stage09_semantics(cfg, design_pool_table, family_name, options)
%EVALUATE_DESIGN_POOL_WITH_STAGE09_SEMANTICS Evaluate an explicit design pool using Stage09-compatible semantics.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
end
if nargin < 2 || ~istable(design_pool_table)
    error('evaluate_design_pool_with_stage09_semantics requires cfg and design_pool_table.');
end
if nargin < 3 || isempty(family_name)
    family_name = 'nominal';
end
if nargin < 4 || isempty(options)
    options = struct();
end

family_token = lower(strtrim(char(string(family_name))));
overrides = struct();
overrides.use_parallel = logical(local_getfield_or(options, 'use_parallel', true));
if isfield(options, 'heading_subset_max') && ~isempty(options.heading_subset_max)
    overrides.heading_subset_max = options.heading_subset_max;
end

eval_out = evaluate_design_pool_with_stage09(cfg, design_pool_table, family_token, overrides);
eval_table = eval_out.full_theta_table;
if isempty(eval_table)
    out = struct();
    out.cfg = eval_out.cfg;
    out.family_name = string(family_token);
    out.design_pool_table = design_pool_table;
    out.eval_table = eval_table;
    out.feasible_table = eval_out.feasible_theta_table;
    out.summary = eval_out.summary;
    return;
end

eval_table.family_name = repmat(string(family_token), height(eval_table), 1);
eval_table.sensor_group = repmat(string(local_getfield_or(options, 'sensor_group', "")), height(eval_table), 1);
eval_table.sensor_label = repmat(string(local_get_cfg_sensor_field(eval_out.cfg, 'sensor_label', "")), height(eval_table), 1);
eval_table.max_off_boresight_deg = repmat(local_get_sensor_numeric(eval_out.cfg, 'max_off_boresight_deg'), height(eval_table), 1);
eval_table.sigma_angle_arcsec = repmat(local_get_sensor_numeric(eval_out.cfg, 'sigma_angle_arcsec'), height(eval_table), 1);
eval_table.sigma_angle_rad = repmat(local_get_sensor_numeric(eval_out.cfg, 'sigma_angle_rad'), height(eval_table), 1);
eval_table.semantic_mode = repmat("closedD", height(eval_table), 1);
eval_table.source_stage = repmat("Stage09", height(eval_table), 1);
if ismember('DG_worst', eval_table.Properties.VariableNames) && ~ismember('D_G_min', eval_table.Properties.VariableNames)
    eval_table.D_G_min = eval_table.DG_worst;
end
if ismember('joint_feasible', eval_table.Properties.VariableNames) && ~ismember('feasible_flag', eval_table.Properties.VariableNames)
    eval_table.feasible_flag = logical(eval_table.joint_feasible);
end
if ~ismember('feasible', eval_table.Properties.VariableNames)
    eval_table.feasible = logical(eval_table.feasible_flag);
end

out = struct();
out.cfg = eval_out.cfg;
out.family_name = string(family_token);
out.design_pool_table = design_pool_table;
out.eval_table = eval_table;
out.feasible_table = eval_out.feasible_theta_table;
out.summary = struct( ...
    'family_name', string(family_token), ...
    'sensor_group', string(local_getfield_or(options, 'sensor_group', "")), ...
    'sensor_label', string(local_get_cfg_sensor_field(eval_out.cfg, 'sensor_label', "")), ...
    'max_off_boresight_deg', local_get_sensor_numeric(eval_out.cfg, 'max_off_boresight_deg'), ...
    'sigma_angle_arcsec', local_get_sensor_numeric(eval_out.cfg, 'sigma_angle_arcsec'), ...
    'sigma_angle_rad', local_get_sensor_numeric(eval_out.cfg, 'sigma_angle_rad'), ...
    'num_total', height(eval_table), ...
    'num_feasible', height(eval_out.feasible_theta_table), ...
    'feasible_ratio', local_safe_divide(height(eval_out.feasible_theta_table), height(eval_table)), ...
    'minimum_feasible_Ns', local_min_or_missing(eval_out.feasible_theta_table, 'Ns'), ...
    'best_joint_margin', local_max_or_nan(eval_out.feasible_theta_table, 'joint_margin'), ...
    'source_stage', "Stage09");
end

function value = local_min_or_missing(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = missing;
    return;
end
value = min(T.(field_name), [], 'omitnan');
if ~isfinite(value)
    value = missing;
end
end

function value = local_max_or_nan(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
value = max(T.(field_name), [], 'omitnan');
end

function value = local_safe_divide(a, b)
if b == 0
    value = 0;
else
    value = a / b;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function value = local_get_cfg_sensor_field(cfg, field_name, fallback)
value = fallback;
if isstruct(cfg) && isfield(cfg, 'sensor') && isstruct(cfg.sensor) && isfield(cfg.sensor, field_name)
    value = cfg.sensor.(field_name);
elseif isstruct(cfg) && isfield(cfg, 'stage09') && isstruct(cfg.stage09)
    stage09_field = ['sensor_' field_name];
    if isfield(cfg.stage09, stage09_field)
        value = cfg.stage09.(stage09_field);
    end
end
end

function value = local_get_sensor_numeric(cfg, field_name)
value = NaN;
candidate = local_get_cfg_sensor_field(cfg, field_name, NaN);
if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
    value = candidate;
end
end
