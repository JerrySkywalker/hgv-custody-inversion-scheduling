function [cfg_out, group] = apply_sensor_param_group_to_cfg(cfg_in, group_name)
%APPLY_SENSOR_PARAM_GROUP_TO_CFG Apply a named sensor-parameter group to the active configuration.

if nargin < 1 || isempty(cfg_in)
    cfg_in = default_params();
end
if nargin < 2 || isempty(group_name)
    group_name = 'baseline';
end

group = get_sensor_param_group(group_name);
cfg_out = cfg_in;

cfg_out.sensor.param_group = group.name;
cfg_out.sensor.sensor_label = group.sensor_label;
cfg_out.sensor.max_off_boresight_deg = group.max_off_boresight_deg;
cfg_out.sensor.sigma_angle_deg = group.angle_resolution_arcsec / 3600;
cfg_out.sensor.sigma_angle_arcsec = group.angle_resolution_arcsec;
cfg_out.sensor.sigma_angle_rad = group.angle_resolution_rad;

cfg_out.stage03.max_offnadir_deg = group.max_off_boresight_deg;
cfg_out.stage03.sensor_group_name = group.name;

cfg_out.stage04.sigma_angle_deg = group.angle_resolution_arcsec / 3600;
cfg_out.stage04.sigma_angle_rad = group.angle_resolution_rad;
cfg_out.stage04.sensor_group_name = group.name;
end
