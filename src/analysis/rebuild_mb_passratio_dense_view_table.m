function [dense_table, rebuild_meta] = rebuild_mb_passratio_dense_view_table(source_table, search_domain, options)
%REBUILD_MB_PASSRATIO_DENSE_VIEW_TABLE Rebuild a dense pass-ratio view table on a target Ns grid.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

raw_eval_table = local_getfield_or(options, 'raw_eval_table', table());
ns_field = char(string(local_getfield_or(options, 'ns_field', 'Ns')));
group_fields = cellstr(string(local_getfield_or(options, 'group_fields', {})));
target_ns_grid = reshape(local_getfield_or(options, 'target_ns_grid', []), 1, []);
output_value_field = char(string(local_getfield_or(options, 'output_value_field', local_detect_output_field(source_table))));
raw_value_field = char(string(local_getfield_or(options, 'raw_value_field', 'pass_ratio')));

dense_table = table();
rebuild_meta = struct( ...
    'dense_rebuild_used', true, ...
    'inherited_from_effective_dense', false, ...
    'zero_padding_used', false, ...
    'sparse_projection_used', false, ...
    'source_table_kind', "aggregate_source_table", ...
    'target_ns_min', NaN, ...
    'target_ns_max', NaN, ...
    'target_ns_count', 0, ...
    'num_unique_ns_plotted', 0, ...
    'num_nonzero_rows', 0, ...
    'missing_target_row_count', 0, ...
    'pass_fail', false);

target_ns_grid = unique(target_ns_grid(isfinite(target_ns_grid)), 'sorted');
if isempty(target_ns_grid)
    target_ns_grid = local_make_target_ns_grid(search_domain, source_table, ns_field);
end
if isempty(target_ns_grid)
    rebuild_meta.source_table_kind = "no_target_ns_grid";
    return;
end

rebuild_meta.target_ns_min = min(target_ns_grid);
rebuild_meta.target_ns_max = max(target_ns_grid);
rebuild_meta.target_ns_count = numel(target_ns_grid);

if ~isempty(raw_eval_table)
    rebuild_meta.source_table_kind = "raw_eval_table_dense_rebuild";
end

group_source = source_table;
if ~isempty(raw_eval_table) && all(ismember(group_fields, raw_eval_table.Properties.VariableNames))
    group_source = raw_eval_table;
end

if isempty(group_fields)
    group_rows = table(1, 'VariableNames', {'group_id_tmp'});
    group_fields = {'group_id_tmp'};
    if isempty(group_source)
        group_source = group_rows;
    else
        group_source.group_id_tmp = ones(height(group_source), 1);
    end
else
    missing_group_fields = group_fields(~ismember(group_fields, group_source.Properties.VariableNames));
    if ~isempty(missing_group_fields)
        error('rebuild_mb_passratio_dense_view_table:MissingGroupField', ...
            'Missing group fields: %s', strjoin(missing_group_fields, ', '));
    end
    group_rows = unique(group_source(:, group_fields), 'rows', 'stable');
end

row_chunks = cell(height(group_rows), 1);
missing_rows = 0;
for idx_group = 1:height(group_rows)
    group_row = group_rows(idx_group, :);
    row_chunks{idx_group} = local_build_group_dense_rows(source_table, raw_eval_table, group_row, group_fields, target_ns_grid, ns_field, output_value_field, raw_value_field);
    missing_rows = missing_rows + sum(~logical(local_pick_column(row_chunks{idx_group}, 'point_evaluated', false)));
end

if ~isempty(row_chunks)
    dense_table = vertcat(row_chunks{:});
end
if ismember('group_id_tmp', dense_table.Properties.VariableNames)
    dense_table.group_id_tmp = [];
end

dense_table = local_sort_dense_table(dense_table, group_fields, ns_field);
rebuild_meta.missing_target_row_count = missing_rows;
rebuild_meta.num_unique_ns_plotted = numel(unique(local_pick_column(dense_table, ns_field, NaN)));
value_column = local_pick_column(dense_table, output_value_field, NaN);
rebuild_meta.num_nonzero_rows = sum(isfinite(value_column) & abs(value_column) > 0);
rebuild_meta.pass_fail = ~isempty(dense_table) && any(isfinite(value_column));
end

function group_table = local_build_group_dense_rows(source_table, raw_eval_table, group_row, group_fields, target_ns_grid, ns_field, output_value_field, raw_value_field)
row_count = numel(target_ns_grid);
base_fields = [group_fields, {ns_field, output_value_field, 'num_feasible', 'num_total', 'point_evaluated', 'dense_rebuild_missing'}];
rows = cell(row_count, numel(base_fields));
source_sub = local_filter_group_rows(source_table, group_row, group_fields);
raw_sub = local_filter_group_rows(raw_eval_table, group_row, group_fields);

for idx = 1:row_count
    ns_value = target_ns_grid(idx);
    rows(idx, :) = local_build_dense_row(source_sub, raw_sub, group_row, group_fields, ns_field, ns_value, output_value_field, raw_value_field);
end

group_table = cell2table(rows, 'VariableNames', base_fields);
group_table = local_cast_dense_table(group_table);
end

function row = local_build_dense_row(source_sub, raw_sub, group_row, group_fields, ns_field, ns_value, output_value_field, raw_value_field)
row = cell(1, numel(group_fields) + 6);
cursor = 0;
for idx = 1:numel(group_fields)
    cursor = cursor + 1;
    row{cursor} = group_row.(group_fields{idx})(1);
end
cursor = cursor + 1;
row{cursor} = ns_value;

raw_hit = table();
if ~isempty(raw_sub) && ismember(ns_field, raw_sub.Properties.VariableNames)
    raw_hit = raw_sub(raw_sub.(ns_field) == ns_value, :);
end
source_hit = table();
if isempty(raw_hit) && ~isempty(source_sub) && ismember(ns_field, source_sub.Properties.VariableNames)
    source_hit = source_sub(source_sub.(ns_field) == ns_value, :);
end

if ~isempty(raw_hit) && ismember(raw_value_field, raw_hit.Properties.VariableNames)
    row{cursor + 1} = max(raw_hit.(raw_value_field), [], 'omitnan');
    row{cursor + 2} = local_sum_feasible(raw_hit);
    row{cursor + 3} = height(raw_hit);
    row{cursor + 4} = true;
    row{cursor + 5} = false;
elseif ~isempty(source_hit)
    row{cursor + 1} = local_pick_numeric(source_hit, output_value_field, NaN);
    row{cursor + 2} = local_pick_numeric(source_hit, 'num_feasible', NaN);
    row{cursor + 3} = local_pick_numeric(source_hit, 'num_total', NaN);
    row{cursor + 4} = true;
    row{cursor + 5} = false;
else
    row{cursor + 1} = NaN;
    row{cursor + 2} = 0;
    row{cursor + 3} = 0;
    row{cursor + 4} = false;
    row{cursor + 5} = true;
end
end

function value = local_sum_feasible(T)
if isempty(T)
    value = 0;
elseif ismember('feasible_flag', T.Properties.VariableNames)
    value = sum(logical(T.feasible_flag));
elseif ismember('joint_feasible', T.Properties.VariableNames)
    value = sum(logical(T.joint_feasible));
else
    value = 0;
end
end

function value = local_pick_numeric(T, field_name, fallback)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = fallback;
    return;
end
value = T.(field_name)(1);
if ~isnumeric(value) || ~isscalar(value)
    value = fallback;
end
end

function values = local_pick_column(T, field_name, fallback)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
else
    values = repmat(fallback, height(T), 1);
end
end

function T = local_cast_dense_table(T)
string_fields = {};
logical_fields = {'point_evaluated', 'dense_rebuild_missing'};
for idx = 1:numel(T.Properties.VariableNames)
    field_name = T.Properties.VariableNames{idx};
    column = T.(field_name);
    if iscell(column) && (isempty(column) || ischar(column{1}) || isstring(column{1}))
        string_fields{end + 1} = field_name; %#ok<AGROW>
    end
end
string_fields = unique(string_fields, 'stable');
for idx = 1:numel(string_fields)
    T.(string_fields{idx}) = string(T.(string_fields{idx}));
end
for idx = 1:numel(logical_fields)
    if ismember(logical_fields{idx}, T.Properties.VariableNames)
        T.(logical_fields{idx}) = logical(T.(logical_fields{idx}));
    end
end
numeric_fields = setdiff(T.Properties.VariableNames, [string_fields, logical_fields], 'stable');
for idx = 1:numel(numeric_fields)
    if ~isnumeric(T.(numeric_fields{idx}))
        T.(numeric_fields{idx}) = double(T.(numeric_fields{idx}));
    end
end
end

function T = local_sort_dense_table(T, group_fields, ns_field)
if isempty(T)
    return;
end
sort_fields = [group_fields(:).', {ns_field}];
sort_fields = unique(sort_fields, 'stable');
T = sortrows(T, sort_fields);
end

function filtered = local_filter_group_rows(T, group_row, group_fields)
if isempty(T)
    filtered = T;
    return;
end
mask = true(height(T), 1);
for idx = 1:numel(group_fields)
    field_name = group_fields{idx};
    if ~ismember(field_name, T.Properties.VariableNames)
        mask = false(height(T), 1);
        break;
    end
    value = group_row.(field_name)(1);
    column = T.(field_name);
    if isstring(column) || iscellstr(column) || ischar(column)
        mask = mask & strcmp(string(column), string(value));
    else
        mask = mask & (column == value);
    end
end
filtered = T(mask, :);
end

function target_ns_grid = local_make_target_ns_grid(search_domain, source_table, ns_field)
source_ns = [];
if istable(source_table) && ismember(ns_field, source_table.Properties.VariableNames)
    source_ns = unique(source_table.(ns_field), 'sorted');
    source_ns = source_ns(isfinite(source_ns));
end
step = local_first_finite_positive( ...
    local_getfield_or(search_domain, 'ns_search_step', NaN), ...
    local_min_spacing(source_ns), ...
    4);
ns_min = local_first_finite(local_getfield_or(search_domain, 'effective_ns_min', NaN), local_getfield_or(search_domain, 'ns_search_min', NaN), local_min_or_nan(source_ns));
ns_max = local_first_finite(local_getfield_or(search_domain, 'effective_ns_max', NaN), local_getfield_or(search_domain, 'ns_search_max', NaN), local_max_or_nan(source_ns));
target_ns_grid = local_make_ns_grid(ns_min, ns_max, step);
end

function field_name = local_detect_output_field(source_table)
field_name = "max_pass_ratio";
candidates = ["max_pass_ratio", "overlay_pass_ratio", "max_pass_ratio_legacyDG", "max_pass_ratio_closedD"];
if ~istable(source_table)
    return;
end
for idx = 1:numel(candidates)
    if ismember(candidates(idx), source_table.Properties.VariableNames)
        field_name = candidates(idx);
        return;
    end
end
end

function value = local_min_or_nan(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
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

function step = local_min_spacing(values)
values = unique(values(isfinite(values)), 'sorted');
if numel(values) < 2
    step = NaN;
else
    step = min(diff(values));
end
end

function ns_grid = local_make_ns_grid(min_ns, max_ns, step)
if ~all(isfinite([min_ns, max_ns, step])) || step <= 0 || min_ns > max_ns
    ns_grid = [];
    return;
end
count = floor((max_ns - min_ns) / step + 0.5);
ns_grid = min_ns + (0:count) * step;
if isempty(ns_grid) || abs(ns_grid(end) - max_ns) > 1.0e-9
    ns_grid = [ns_grid, max_ns]; %#ok<AGROW>
end
ns_grid = unique(round(ns_grid / step) * step, 'sorted');
end

function value = local_first_finite(varargin)
value = NaN;
for idx = 1:nargin
    candidate = varargin{idx};
    if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
        value = candidate;
        return;
    end
end
end

function value = local_first_finite_positive(varargin)
value = NaN;
for idx = 1:nargin
    candidate = varargin{idx};
    if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate) && candidate > 0
        value = candidate;
        return;
    end
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
