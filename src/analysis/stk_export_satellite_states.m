function out = stk_export_satellite_states(stk_app, sat_path, sat_name, cfg, export_dir)
%STK_EXPORT_SATELLITE_STATES Export satellite states from STK to table/CSV.

start_time = local_format_stk_time(cfg.shared_scenarios.start_time);
stop_time = local_format_stk_time(cfg.shared_scenarios.stop_time);
step_s = cfg.shared_scenarios.sample_time_s;

ensure_dir(export_dir);
csv_path = fullfile(export_dir, sprintf('%s_states_fixed.csv', sat_name));

out = struct();
out.sat_path = string(sat_path);
out.sat_name = string(sat_name);
out.csv_path = string(csv_path);

styles = {'Cartesian Position', 'Cartesian Position/Fixed', 'Cartesian Position Velocity'};
cmd_templates = { ...
    'ReportCreate %s Type Export Style "%s" File "%s" TimePeriod UseScenarioInterval TimeStep %g', ...
    'ReportCreate %s Type Export Style "%s" File "%s" TimePeriod "%s" "%s" TimeStep %g'};

success = false;
last_error = [];
for iStyle = 1:numel(styles)
    for iCmd = 1:numel(cmd_templates)
        try
            if iCmd == 1
                cmd = sprintf(cmd_templates{iCmd}, char(sat_path), styles{iStyle}, strrep(csv_path, '\', '\\'), step_s);
            else
                cmd = sprintf(cmd_templates{iCmd}, char(sat_path), styles{iStyle}, strrep(csv_path, '\', '\\'), start_time, stop_time, step_s);
            end
            stk_app.ExecuteCommand(cmd);
            if isfile(csv_path)
                T = readtable(csv_path);
                out.table = local_normalize_report_table(T);
                local_mirror_export(out.table, sat_name, cfg);
                success = true;
                break;
            end
        catch ME
            last_error = ME;
        end
    end
    if success
        break;
    end
end

function local_mirror_export(T, sat_name, cfg)
mirror_root = cfg.shared_scenarios.stk.mirror_export_root;
ensure_dir(mirror_root);
mirror_path = fullfile(mirror_root, sprintf('%s_states_fixed.csv', sat_name));
writetable(T, mirror_path);
end

if ~success
    if isempty(last_error)
        error('Failed to export STK satellite states for %s.', sat_name);
    else
        rethrow(last_error);
    end
end
end

function txt = local_format_stk_time(value)
dt = datetime(value, 'TimeZone', 'UTC');
vec = datevec(dt);
month_names = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
txt = sprintf('%d %s %04d %02d:%02d:%05.2f', ...
    vec(3), month_names{vec(2)}, vec(1), vec(4), vec(5), vec(6));
end

function T = local_normalize_report_table(T)
names = string(T.Properties.VariableNames);
time_idx = find(contains(lower(names), "time"), 1, 'first');
x_idx = find(lower(names) == "x", 1, 'first');
y_idx = find(lower(names) == "y", 1, 'first');
z_idx = find(lower(names) == "z", 1, 'first');

if isempty(time_idx) || isempty(x_idx) || isempty(y_idx) || isempty(z_idx)
    error('Failed to normalize STK report table columns.');
end

T = T(:, [time_idx, x_idx, y_idx, z_idx]);
T.Properties.VariableNames = {'time_s', 'x_km', 'y_km', 'z_km'};
scale = max(abs([T.x_km; T.y_km; T.z_km]));
if scale > 1e5
    T{:, {'x_km', 'y_km', 'z_km'}} = T{:, {'x_km', 'y_km', 'z_km'}} / 1000;
end
end
