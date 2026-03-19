function label = format_mb_profile_with_sensor_label(profile_in, sensor_group_in, cfg, detail_level)
%FORMAT_MB_PROFILE_WITH_SENSOR_LABEL Combine MB profile and sensor labels.

if nargin < 1 || isempty(profile_in)
    profile_in = 'mb_default';
end
if nargin < 2 || isempty(sensor_group_in)
    sensor_group_in = 'baseline';
end
if nargin < 3
    cfg = [];
end
if nargin < 4 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

profile_label = format_mb_search_profile_label(profile_in, cfg, detail_level);
sensor_label = format_mb_sensor_group_label(sensor_group_in, detail_level);
label = string(sprintf('%s | %s', profile_label, sensor_label));
end
