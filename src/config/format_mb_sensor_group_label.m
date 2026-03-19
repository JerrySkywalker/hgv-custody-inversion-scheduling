function label = format_mb_sensor_group_label(group_in, detail_level)
%FORMAT_MB_SENSOR_GROUP_LABEL Human-readable MB sensor-group label.

if nargin < 1 || isempty(group_in)
    group_in = 'baseline';
end
if nargin < 2 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

if isstruct(group_in)
    group = group_in;
else
    group = get_sensor_param_group(group_in);
end

base = sprintf('%s (offnadir=%g deg, angle_res=%g arcsec)', ...
    char(string(group.name)), ...
    group.max_off_boresight_deg, ...
    group.angle_resolution_arcsec);

extras = strings(0, 1);
if strcmpi(char(string(group.name)), 'stage05_strict_reference')
    extras(end + 1, 1) = "strict domain lock"; %#ok<AGROW>
end
if strcmpi(char(string(detail_level)), 'detailed') && isfield(group, 'description') && strlength(string(group.description)) > 0
    extras(end + 1, 1) = string(group.description); %#ok<AGROW>
end

if isempty(extras)
    label = string(base);
else
    label = string(sprintf('%s, %s', base, strjoin(cellstr(extras), ', ')));
end
end
