function [view_table, padding_summary, view_meta] = build_mb_passratio_domain_view(source_table, search_domain, options)
%BUILD_MB_PASSRATIO_DOMAIN_VIEW Build history/effective/zoom data views for pass-ratio exports.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

domain_view = string(local_getfield_or(options, 'domain_view', "effective_full_range"));
ns_field = char(string(local_getfield_or(options, 'ns_field', 'Ns')));
group_fields = cellstr(string(local_getfield_or(options, 'group_fields', {})));
value_fields = cellstr(string(local_getfield_or(options, 'value_fields', {})));
fill_values = local_getfield_or(options, 'fill_values', struct());
recompute_mode = string(local_getfield_or(options, 'recompute_mode', "none"));
history_fill_mode = string(local_getfield_or(options, 'history_fill_mode', "zero"));
history_origin = string(local_getfield_or(options, 'history_origin', "initial_ns_min"));
figure_name = string(local_getfield_or(options, 'figure_name', ""));

initial_range = reshape(local_getfield_or(search_domain, 'Ns_initial_range', [NaN, NaN, NaN]), 1, []);
initial_ns_min = local_first_finite(local_getfield_or(search_domain, 'history_ns_min', NaN), local_pick_initial(initial_range, 1));
effective_ns_min = local_first_finite(local_getfield_or(search_domain, 'effective_ns_min', NaN), local_getfield_or(search_domain, 'ns_search_min', NaN));
final_ns_max = local_first_finite(local_getfield_or(search_domain, 'history_ns_max', NaN), local_getfield_or(search_domain, 'effective_ns_max', NaN), local_getfield_or(search_domain, 'ns_search_max', NaN));
ns_step = local_first_finite_positive(local_getfield_or(search_domain, 'ns_search_step', NaN), local_pick_initial(initial_range, 2), local_min_spacing(source_table, ns_field), 4);

source_ns = local_get_column(source_table, ns_field);
source_ns = unique(source_ns(isfinite(source_ns)), 'sorted');
if ~isfinite(initial_ns_min)
    initial_ns_min = local_min_or_nan(source_ns);
end
if ~isfinite(effective_ns_min)
    effective_ns_min = local_min_or_nan(source_ns);
end
if ~isfinite(final_ns_max)
    final_ns_max = local_max_or_nan(source_ns);
end

view_table = source_table;
padding_summary = local_empty_padding_summary();
view_meta = struct( ...
    'domain_view', domain_view, ...
    'history_padding_applied', false, ...
    'history_fill_mode', "", ...
    'history_origin', "", ...
    'initial_ns_min', initial_ns_min, ...
    'effective_ns_min', effective_ns_min, ...
    'final_ns_max', final_ns_max, ...
    'source_table_min_ns', local_min_or_nan(source_ns), ...
    'source_table_max_ns', local_max_or_nan(source_ns), ...
    'source_table_row_count', height(source_table), ...
    'root_cause_tag', "correct");

if domain_view ~= "history_full" || isempty(source_table)
    return;
end

if ~isfinite(initial_ns_min) || ~isfinite(final_ns_max) || ~isfinite(ns_step)
    view_meta.root_cause_tag = "source_table_tail_only";
    return;
end

history_min = initial_ns_min;
if history_origin == "zero"
    history_min = 0;
end

ns_grid = local_make_ns_grid(history_min, final_ns_max, ns_step);
if isempty(ns_grid)
    view_meta.root_cause_tag = "source_table_tail_only";
    return;
end

missing_group_fields = group_fields(~ismember(group_fields, source_table.Properties.VariableNames));
if ~isempty(missing_group_fields)
    error('build_mb_passratio_domain_view:MissingGroupField', ...
        'Missing group fields: %s', strjoin(missing_group_fields, ', '));
end

if isempty(group_fields)
    group_rows = table(1, 'VariableNames', {'group_id_tmp'});
    source_table.group_id_tmp = ones(height(source_table), 1);
    group_fields = {'group_id_tmp'};
else
    group_rows = unique(source_table(:, group_fields), 'rows', 'stable');
end

row_chunks = cell(height(group_rows), 1);
summary_rows = cell(height(group_rows), 1);
padding_applied = false;
for idx_group = 1:height(group_rows)
    group_row = group_rows(idx_group, :);
    sub = local_filter_group_rows(source_table, group_row, group_fields);
    original_ns = unique(local_get_column(sub, ns_field));
    original_ns = original_ns(isfinite(original_ns));

    skeleton = local_build_skeleton_table(group_row, group_fields, ns_field, ns_grid);
    joined = outerjoin(skeleton, sub, 'Keys', [group_fields, {ns_field}], 'MergeKeys', true, 'Type', 'left');

    padded_mask = ~ismember(joined.(ns_field), original_ns);
    joined = local_fill_missing_columns(joined, value_fields, fill_values, padded_mask, history_fill_mode);
    joined = local_apply_recompute_mode(joined, recompute_mode);
    joined.history_padded_row = padded_mask;
    joined.history_padding_applied = repmat(any(padded_mask), height(joined), 1);
    joined.history_fill_mode = repmat(history_fill_mode, height(joined), 1);
    joined.history_origin = repmat(history_origin, height(joined), 1);

    row_chunks{idx_group} = joined;
    padding_applied = padding_applied || any(padded_mask);
    summary_rows{idx_group} = local_build_padding_summary_row(figure_name, group_row, group_fields, initial_ns_min, final_ns_max, numel(original_ns), sum(padded_mask), history_fill_mode, any(padded_mask));
end

view_table = vertcat(row_chunks{:});
view_table = sortrows(view_table, [group_fields, {ns_field}]);
padding_summary = vertcat(summary_rows{:});

if ismember('group_id_tmp', view_table.Properties.VariableNames)
    view_table.group_id_tmp = [];
end

view_meta.history_padding_applied = padding_applied;
view_meta.history_fill_mode = history_fill_mode;
view_meta.history_origin = history_origin;
view_meta.root_cause_tag = "correct";
end

function joined = local_fill_missing_columns(joined, value_fields, fill_values, padded_mask, history_fill_mode)
for idx = 1:numel(value_fields)
    field_name = value_fields{idx};
    if ~ismember(field_name, joined.Properties.VariableNames)
        continue;
    end
    fill_value = local_fill_value(fill_values, field_name, joined.(field_name), history_fill_mode);
    joined.(field_name) = local_fill_missing(joined.(field_name), fill_value, padded_mask);
end

other_fields = setdiff(joined.Properties.VariableNames, [value_fields, {'history_padded_row', 'history_padding_applied', 'history_fill_mode', 'history_origin'}], 'stable');
for idx = 1:numel(other_fields)
    field_name = other_fields{idx};
    if any(strcmp(field_name, {'Ns', 'h_km', 'family_name', 'i_deg', 'sensor_group', 'sensor_label', 'semantic_mode'}))
        continue;
    end
    if ismember(field_name, value_fields)
        continue;
    end
    if islogical(joined.(field_name))
        joined.(field_name) = local_fill_missing(joined.(field_name), false, padded_mask);
    end
end
end

function joined = local_apply_recompute_mode(joined, recompute_mode)
switch recompute_mode
    case "comparison_gap"
        if all(ismember({'legacy_present', 'closed_present', 'max_pass_ratio_legacyDG', 'max_pass_ratio_closedD', 'passratio_gap'}, joined.Properties.VariableNames))
            joined.legacy_present = logical(joined.legacy_present);
            joined.closed_present = logical(joined.closed_present);
            joined.passratio_gap = joined.max_pass_ratio_closedD - joined.max_pass_ratio_legacyDG;
        end
    otherwise
        % no-op
end
end

function summary_row = local_build_padding_summary_row(figure_name, group_row, group_fields, initial_ns_min, final_ns_max, num_original_points, num_padded_points, history_fill_mode, padding_applied)
summary_row = table( ...
    string(figure_name), ...
    string(local_group_key(group_row, group_fields)), ...
    double(initial_ns_min), ...
    double(final_ns_max), ...
    double(num_original_points), ...
    double(num_padded_points), ...
    string(history_fill_mode), ...
    logical(padding_applied), ...
    'VariableNames', {'figure_name', 'group_key', 'initial_ns_min', 'final_ns_max', 'num_original_points', 'num_padded_points', 'history_fill_mode', 'padding_applied'});
end

function key = local_group_key(group_row, group_fields)
parts = strings(numel(group_fields), 1);
for idx = 1:numel(group_fields)
    value = group_row.(group_fields{idx});
    if iscell(value)
        value = value{1};
    end
    parts(idx) = string(group_fields{idx}) + "=" + string(value(1));
end
key = strjoin(parts, ";");
end

function filtered = local_filter_group_rows(T, group_row, group_fields)
mask = true(height(T), 1);
for idx = 1:numel(group_fields)
    field_name = group_fields{idx};
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

function skeleton = local_build_skeleton_table(group_row, group_fields, ns_field, ns_grid)
height_grid = numel(ns_grid);
skeleton = table();
for idx = 1:numel(group_fields)
    value = group_row.(group_fields{idx});
    if isstring(value)
        skeleton.(group_fields{idx}) = repmat(string(value(1)), height_grid, 1);
    elseif iscell(value)
        skeleton.(group_fields{idx}) = repmat(value(1), height_grid, 1);
    else
        skeleton.(group_fields{idx}) = repmat(value(1), height_grid, 1);
    end
end
skeleton.(ns_field) = ns_grid(:);
end

function filled = local_fill_missing(data, fill_value, padded_mask)
filled = data;
if isnumeric(filled)
    mask = isnan(filled);
    if nargin >= 3
        mask = mask | padded_mask;
    end
    filled(mask) = fill_value;
elseif islogical(filled)
    if nargin >= 3
        filled(padded_mask) = logical(fill_value);
    end
elseif isstring(filled)
    mask = ismissing(filled);
    if nargin >= 3
        mask = mask | padded_mask;
    end
    filled(mask) = string(fill_value);
else
    % leave unsupported types untouched
end
end

function fill_value = local_fill_value(fill_values, field_name, sample_data, history_fill_mode)
if isstruct(fill_values) && isfield(fill_values, field_name)
    fill_value = fill_values.(field_name);
    return;
end
if islogical(sample_data)
    fill_value = false;
elseif isnumeric(sample_data)
    if history_fill_mode == "nan"
        fill_value = NaN;
    else
        fill_value = 0;
    end
elseif isstring(sample_data)
    fill_value = "";
else
    fill_value = [];
end
end

function values = local_get_column(T, field_name)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
else
    values = [];
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

function step = local_min_spacing(T, field_name)
values = local_get_column(T, field_name);
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

function value = local_pick_initial(initial_range, idx_pick)
if numel(initial_range) >= idx_pick && isfinite(initial_range(idx_pick))
    value = initial_range(idx_pick);
else
    value = NaN;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function T = local_empty_padding_summary()
T = table('Size', [0, 8], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'string', 'logical'}, ...
    'VariableNames', {'figure_name', 'group_key', 'initial_ns_min', 'final_ns_max', 'num_original_points', 'num_padded_points', 'history_fill_mode', 'padding_applied'});
end
