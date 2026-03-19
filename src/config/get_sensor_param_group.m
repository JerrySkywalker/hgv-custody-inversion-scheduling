function group = get_sensor_param_group(group_name)
%GET_SENSOR_PARAM_GROUP Return a normalized sensor parameter group definition.

if nargin < 1 || strlength(string(group_name)) == 0
    error('get_sensor_param_group requires a non-empty group name.');
end

name = lower(strtrim(char(string(group_name))));
switch name
    case 'baseline'
        group = local_build_group( ...
            'baseline', ...
            50, ...
            10, ...
            'Baseline sensor group: 50 deg max off-boresight and 10 arcsec angular resolution.');
    case 'optimistic'
        group = local_build_group( ...
            'optimistic', ...
            50, ...
            5, ...
            'Optimistic sensor group: 50 deg max off-boresight and 5 arcsec angular resolution.');
    case 'robust'
        group = local_build_group( ...
            'robust', ...
            50, ...
            15, ...
            'Robust sensor group: 50 deg max off-boresight and 15 arcsec angular resolution.');
    otherwise
        error('Unknown sensor parameter group: %s', string(group_name));
end
end

function group = local_build_group(name, max_off_boresight_deg, angle_resolution_arcsec, description)
group = struct();
group.name = string(name);
group.max_off_boresight_deg = max_off_boresight_deg;
group.angle_resolution_arcsec = angle_resolution_arcsec;
group.angle_resolution_rad = deg2rad(angle_resolution_arcsec / 3600);
group.description = string(description);
group.notes = group.description;
group.sensor_label = sprintf('%s (%g deg, %g arcsec)', name, max_off_boresight_deg, angle_resolution_arcsec);
end
