function summary_table = build_mb_fullnight_run_summary(fullnight_root, profile_name, force_fresh)
%BUILD_MB_FULLNIGHT_RUN_SUMMARY Summarize a fullnight MB run across heights.

if nargin < 1 || strlength(string(fullnight_root)) == 0
    error('build_mb_fullnight_run_summary requires fullnight_root.');
end
if nargin < 2 || strlength(string(profile_name)) == 0
    profile_name = "";
end
if nargin < 3 || isempty(force_fresh)
    force_fresh = true;
end

tables_dir = fullfile(char(string(fullnight_root)), 'tables');
expandable_csv = fullfile(tables_dir, 'MB_expandable_search_summary.csv');
frontier_csv = fullfile(tables_dir, 'MB_frontier_coverage_report.csv');
comparison_files = dir(fullfile(tables_dir, 'MB_comparison_summary_h*_*.csv'));

if exist(expandable_csv, 'file') ~= 2 || isempty(comparison_files)
    summary_table = table();
    return;
end

expandable = readtable(expandable_csv, 'TextType', 'string');
frontier = local_read_if_present(frontier_csv);

rows = cell(0, 1);
for idx_file = 1:numel(comparison_files)
    comparison_path = fullfile(comparison_files(idx_file).folder, comparison_files(idx_file).name);
    comparison_summary = readtable(comparison_path, 'TextType', 'string');
    if isempty(comparison_summary)
        continue;
    end

    for idx_row = 1:height(comparison_summary)
        comparison_row = comparison_summary(idx_row, :);
        height_km = double(comparison_row.h_km);
        family_name = string(local_pick_table_value(comparison_row, 'family_name', ""));
        sensor_group = string(local_infer_sensor_group(comparison_row, comparison_files(idx_file).name));

        legacy_expand = local_pick_expand_row(expandable, "legacyDG", sensor_group, family_name, height_km);
        closed_expand = local_pick_expand_row(expandable, "closedD", sensor_group, family_name, height_km);
        legacy_frontier = local_pick_frontier_row(frontier, "legacyDG", sensor_group, family_name, height_km);
        closed_frontier = local_pick_frontier_row(frontier, "closedD", sensor_group, family_name, height_km);

        grade_path = fullfile(tables_dir, replace(comparison_files(idx_file).name, 'summary', 'export_grade'));
        comparison_grade = local_read_if_present(grade_path);
        comparison_paper_ready = local_pick_comparison_paper_ready(comparison_row, comparison_grade);

        rows{end + 1, 1} = { ... %#ok<AGROW>
            height_km, ...
            string(profile_name), ...
            logical(force_fresh), ...
            local_max_or_nan([local_pick_table_value(legacy_expand, 'final_ns_search_max', NaN), local_pick_table_value(closed_expand, 'final_ns_search_max', NaN)]), ...
            local_max_or_nan([local_pick_table_value(legacy_expand, 'expansion_iterations', NaN), local_pick_table_value(closed_expand, 'expansion_iterations', NaN)]), ...
            local_join_stop_reasons(local_pick_table_value(legacy_expand, 'stop_reason', ""), local_pick_table_value(closed_expand, 'stop_reason', "")), ...
            logical(local_pick_table_value(comparison_row, 'right_plateau_reached_legacy', false)), ...
            logical(local_pick_table_value(comparison_row, 'right_plateau_reached_closed', false)), ...
            double(local_pick_table_value(legacy_frontier, 'frontier_defined_count', NaN)), ...
            double(local_pick_table_value(closed_frontier, 'frontier_defined_count', NaN)), ...
            logical(comparison_paper_ready)};
    end
end

if isempty(rows)
    summary_table = table();
    return;
end

summary_table = cell2table(vertcat(rows{:}), 'VariableNames', { ...
    'height_km', 'profile_name', 'force_fresh', 'final_ns_search_max', 'expansion_iterations', ...
    'stop_reason', 'right_plateau_reached_legacy', 'right_plateau_reached_closed', ...
    'frontier_defined_count_legacy', 'frontier_defined_count_closed', 'comparison_paper_ready'});
summary_table.height_km = double(summary_table.height_km);
summary_table.profile_name = string(summary_table.profile_name);
summary_table.force_fresh = logical(summary_table.force_fresh);
summary_table.final_ns_search_max = double(summary_table.final_ns_search_max);
summary_table.expansion_iterations = double(summary_table.expansion_iterations);
summary_table.stop_reason = string(summary_table.stop_reason);
summary_table.right_plateau_reached_legacy = logical(summary_table.right_plateau_reached_legacy);
summary_table.right_plateau_reached_closed = logical(summary_table.right_plateau_reached_closed);
summary_table.frontier_defined_count_legacy = double(summary_table.frontier_defined_count_legacy);
summary_table.frontier_defined_count_closed = double(summary_table.frontier_defined_count_closed);
summary_table.comparison_paper_ready = logical(summary_table.comparison_paper_ready);
summary_table = sortrows(summary_table, 'height_km');
end

function T = local_read_if_present(file_path)
if exist(file_path, 'file') == 2
    T = readtable(file_path, 'TextType', 'string');
else
    T = table();
end
end

function row = local_pick_expand_row(T, semantic_mode, sensor_group, family_name, height_km)
row = table();
if isempty(T)
    return;
end
mask = string(local_pick_table_column(T, 'semantic_mode')) == string(semantic_mode) & ...
    string(local_pick_table_column(T, 'sensor_group')) == string(sensor_group) & ...
    string(local_pick_table_column(T, 'family_name')) == string(family_name) & ...
    double(local_pick_table_column(T, 'height_km')) == double(height_km);
    if any(mask)
        row = T(find(mask, 1, 'first'), :);
    end
end

function row = local_pick_frontier_row(T, semantic_mode, sensor_group, family_name, height_km)
row = table();
if isempty(T)
    return;
end
mask = string(local_pick_table_column(T, 'semantic_mode')) == string(semantic_mode) & ...
    string(local_pick_table_column(T, 'sensor_group')) == string(sensor_group) & ...
    string(local_pick_table_column(T, 'family_name')) == string(family_name) & ...
    double(local_pick_table_column(T, 'h_km')) == double(height_km);
if any(mask)
    row = T(find(mask, 1, 'first'), :);
end
end

function sensor_group = local_infer_sensor_group(row, file_name)
sensor_group = string(local_pick_table_value(row, 'sensor_group', ""));
if strlength(sensor_group) > 0
    return;
end

file_name = string(file_name);
tokens = split(erase(file_name, ".csv"), "_");
if numel(tokens) >= 2
    sensor_group = tokens(end);
else
    sensor_group = "";
end
end

function tf = local_pick_comparison_paper_ready(comparison_row, comparison_grade)
tf = logical(local_pick_table_value(comparison_row, 'right_plateau_reached_legacy', false)) && ...
    logical(local_pick_table_value(comparison_row, 'right_plateau_reached_closed', false));
if isempty(comparison_grade)
    return;
end
if ismember('paper_ready_allowed', comparison_grade.Properties.VariableNames)
    tf = tf && all(logical(comparison_grade.paper_ready_allowed));
elseif ismember('export_grade', comparison_grade.Properties.VariableNames)
    tf = tf && all(string(comparison_grade.export_grade) == "paper_candidate");
end
end

function joined = local_join_stop_reasons(legacy_reason, closed_reason)
legacy_reason = string(legacy_reason);
closed_reason = string(closed_reason);
if strlength(legacy_reason) == 0
    joined = closed_reason;
elseif strlength(closed_reason) == 0
    joined = legacy_reason;
elseif legacy_reason == closed_reason
    joined = legacy_reason;
else
    joined = "legacyDG=" + legacy_reason + "; closedD=" + closed_reason;
end
end

function value = local_pick_table_value(T, field_name, fallback)
if istable(T) && ~isempty(T) && ismember(field_name, T.Properties.VariableNames)
    value = T.(field_name)(1);
else
    value = fallback;
end
end

function values = local_pick_table_column(T, field_name)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
else
    values = [];
end
end

function value = local_max_or_nan(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end
