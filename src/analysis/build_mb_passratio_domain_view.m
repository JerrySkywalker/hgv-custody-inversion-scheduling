function [view_table, padding_summary, view_meta] = build_mb_passratio_domain_view(source_table, search_domain, options)
%BUILD_MB_PASSRATIO_DOMAIN_VIEW Build data-layer history/effective/frontier/global views for pass-ratio exports.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

domain_view = local_normalize_domain_view(local_getfield_or(options, 'domain_view', "effective_full_range"));
ns_field = char(string(local_getfield_or(options, 'ns_field', 'Ns')));
group_fields = cellstr(string(local_getfield_or(options, 'group_fields', {})));
value_fields = cellstr(string(local_getfield_or(options, 'value_fields', {})));
fill_values = local_getfield_or(options, 'fill_values', struct());
recompute_mode = string(local_getfield_or(options, 'recompute_mode', "none"));
history_fill_mode = string(local_getfield_or(options, 'history_fill_mode', "zero"));
history_origin = string(local_getfield_or(options, 'history_origin', "initial_ns_min"));
figure_name = string(local_getfield_or(options, 'figure_name', ""));
plot_window = reshape(local_getfield_or(options, 'plot_window', []), 1, []);
resolver_options = local_getfield_or(options, 'resolver_options', struct());
runtime_cfg = local_getfield_or(options, 'runtime', struct());
plot_mode_profile = local_getfield_or(options, 'plot_mode_profile', struct());
raw_eval_table = local_getfield_or(options, 'raw_eval_table', table());
effective_dense_table = local_getfield_or(options, 'effective_dense_table', table());

initial_range = reshape(local_getfield_or(search_domain, 'Ns_initial_range', [NaN, NaN, NaN]), 1, []);
source_ns = local_get_column(source_table, ns_field);
source_ns = unique(source_ns(isfinite(source_ns)), 'sorted');

initial_ns_min = local_first_finite(local_getfield_or(search_domain, 'history_ns_min', NaN), local_pick_initial(initial_range, 1), local_min_or_nan(source_ns));
effective_ns_min = local_first_finite(local_getfield_or(search_domain, 'effective_ns_min', NaN), local_getfield_or(search_domain, 'ns_search_min', NaN), local_min_or_nan(source_ns));
effective_ns_max = local_first_finite(local_getfield_or(search_domain, 'effective_ns_max', NaN), local_getfield_or(search_domain, 'ns_search_max', NaN), local_max_or_nan(source_ns));
final_ns_max = local_first_finite(local_getfield_or(search_domain, 'history_ns_max', NaN), effective_ns_max, local_pick_initial(initial_range, 3), local_max_or_nan(source_ns));
ns_step = local_first_finite_positive(local_getfield_or(search_domain, 'ns_search_step', NaN), local_pick_initial(initial_range, 2), local_min_spacing(source_table, ns_field), 4);
history_origin_min = initial_ns_min;
if history_origin == "zero"
    history_origin_min = 0;
end

view_table = source_table;
padding_summary = local_empty_padding_summary();
view_meta = struct( ...
    'domain_view', domain_view, ...
    'history_padding_applied', false, ...
    'history_fill_mode', "", ...
    'history_origin', "", ...
    'history_origin_min', history_origin_min, ...
    'initial_ns_min', initial_ns_min, ...
    'effective_ns_min', effective_ns_min, ...
    'effective_ns_max', effective_ns_max, ...
    'final_ns_max', final_ns_max, ...
    'source_table_min_ns', local_min_or_nan(source_ns), ...
    'source_table_max_ns', local_max_or_nan(source_ns), ...
    'source_table_row_count', height(source_table), ...
    'view_table_min_ns', local_min_or_nan(source_ns), ...
    'view_table_max_ns', local_max_or_nan(source_ns), ...
    'pass_fail', false, ...
    'root_cause_tag', "correct");

if isempty(source_table) && isempty(raw_eval_table)
    view_meta.root_cause_tag = "source_table_tail_only";
    return;
end

switch domain_view
    case "history_full"
        [view_table, padding_summary, view_meta] = local_build_history_points_view( ...
            source_table, ns_field, group_fields, value_fields, fill_values, recompute_mode, ...
            history_fill_mode, history_origin, history_origin_min, initial_ns_min, final_ns_max, ns_step, figure_name, view_meta);
    case "effective_full_range"
        effective_window = [effective_ns_min, effective_ns_max];
        dense_policy = resolve_mb_plot_data_policy(runtime_cfg, struct( ...
            'plot_mode_profile', plot_mode_profile, ...
            'passratio_mode', "effectiveFullRange"));
        [view_table, view_meta] = local_build_dense_effective_view( ...
            source_table, raw_eval_table, search_domain, ns_field, group_fields, recompute_mode, effective_window, ns_step, options, view_meta, dense_policy);
    case "frontier_zoom"
        if ~local_has_valid_window(plot_window)
            windows = resolve_mb_passratio_plot_windows(source_table, search_domain, resolver_options);
            plot_window = reshape(local_getfield_or(windows, 'frontier_zoom', []), 1, []);
        end
        zoom_policy = resolve_mb_plot_data_policy(runtime_cfg, struct( ...
            'plot_mode_profile', plot_mode_profile, ...
            'passratio_mode', "frontierZoom"));
        [view_table, view_meta] = local_build_frontier_zoom_view( ...
            source_table, raw_eval_table, effective_dense_table, search_domain, ns_field, group_fields, recompute_mode, ...
            [effective_ns_min, effective_ns_max], plot_window, ns_step, options, view_meta, zoom_policy);
    case "global_full_replay"
        global_policy = resolve_mb_plot_data_policy(runtime_cfg, struct( ...
            'plot_mode_profile', plot_mode_profile, ...
            'passratio_mode', "globalFullReplay"));
        [view_table, view_meta] = local_build_global_full_replay_view( ...
            source_table, raw_eval_table, search_domain, ns_field, group_fields, recompute_mode, ...
            initial_ns_min, final_ns_max, ns_step, options, view_meta, global_policy);
    otherwise
        error('build_mb_passratio_domain_view:UnsupportedDomainView', ...
            'Unsupported domain_view: %s', char(domain_view));
end
end

function [view_table, padding_summary, view_meta] = local_build_history_points_view(source_table, ns_field, group_fields, value_fields, fill_values, recompute_mode, history_fill_mode, history_origin, history_origin_min, initial_ns_min, final_ns_max, ns_step, figure_name, view_meta)
%#ok<INUSD>
padding_summary = local_empty_padding_summary();
view_table = source_table;

if ~isfinite(history_origin_min) || ~isfinite(final_ns_max)
    view_meta.root_cause_tag = "source_table_tail_only";
    return;
end

missing_group_fields = group_fields(~ismember(group_fields, source_table.Properties.VariableNames));
if ~isempty(missing_group_fields)
    error('build_mb_passratio_domain_view:MissingGroupField', ...
        'Missing group fields: %s', strjoin(missing_group_fields, ', '));
end

view_table = local_filter_ns_window(source_table, ns_field, [history_origin_min, final_ns_max]);
view_table = local_apply_recompute_mode(view_table, recompute_mode);
view_table = local_sort_view_table(view_table, group_fields, ns_field);
view_table.history_padded_row = false(height(view_table), 1);
view_table.history_padding_applied = false(height(view_table), 1);
view_table.history_fill_mode = repmat("none", height(view_table), 1);
view_table.history_origin = repmat(history_origin, height(view_table), 1);

if isempty(group_fields)
    group_rows = table(1, 'VariableNames', {'group_id_tmp'});
    view_table.group_id_tmp = ones(height(view_table), 1);
    group_fields = {'group_id_tmp'};
else
    group_rows = unique(view_table(:, group_fields), 'rows', 'stable');
end

summary_rows = cell(height(group_rows), 1);
group_pass = true(height(group_rows), 1);
for idx_group = 1:height(group_rows)
    group_row = group_rows(idx_group, :);
    sub = local_filter_group_rows(view_table, group_row, group_fields);
    original_ns = unique(local_get_column(sub, ns_field));
    original_ns = original_ns(isfinite(original_ns));

    if ~isempty(sub)
        match_mask = local_group_mask(view_table, group_row, group_fields);
        view_table.history_padded_row(match_mask, 1) = false;
        view_table.history_padding_applied(match_mask, 1) = false;
        view_table.history_fill_mode(match_mask, 1) = repmat("none", sum(match_mask), 1);
        view_table.history_origin(match_mask, 1) = repmat(history_origin, sum(match_mask), 1);
    end

    group_pass(idx_group) = ~isempty(sub);
    summary_rows{idx_group} = local_build_padding_summary_row( ...
        figure_name, local_group_height_km(sub), group_row, group_fields, initial_ns_min, final_ns_max, ...
        numel(original_ns), 0, "none", history_origin, false, group_pass(idx_group));
end

padding_summary = vertcat(summary_rows{:});

if ismember('group_id_tmp', view_table.Properties.VariableNames)
    view_table.group_id_tmp = [];
end

view_meta.history_padding_applied = false;
view_meta.history_fill_mode = "none";
view_meta.history_origin = history_origin;
view_meta.view_table_min_ns = local_min_or_nan(local_get_column(view_table, ns_field));
view_meta.view_table_max_ns = local_max_or_nan(local_get_column(view_table, ns_field));
view_meta.pass_fail = ~isempty(view_table) && all(group_pass);
view_meta.root_cause_tag = "correct";
end

function [view_table, view_meta] = local_build_windowed_view(source_table, ns_field, group_fields, recompute_mode, window, view_meta, success_tag)
view_table = local_filter_ns_window(source_table, ns_field, window);
view_table = local_apply_recompute_mode(view_table, recompute_mode);
view_table = local_sort_view_table(view_table, group_fields, ns_field);
view_meta.view_table_min_ns = local_min_or_nan(local_get_column(view_table, ns_field));
view_meta.view_table_max_ns = local_max_or_nan(local_get_column(view_table, ns_field));
view_meta.pass_fail = ~isempty(view_table);
if view_meta.pass_fail
    view_meta.root_cause_tag = success_tag;
else
    view_meta.root_cause_tag = "source_table_tail_only";
end
end

function [view_table, view_meta] = local_build_dense_effective_view(source_table, raw_eval_table, search_domain, ns_field, group_fields, recompute_mode, effective_window, ns_step, options, view_meta, policy)
target_ns_grid = local_make_ns_grid(effective_window(1), effective_window(2), ns_step);
dense_options = struct( ...
    'raw_eval_table', raw_eval_table, ...
    'ns_field', ns_field, ...
    'group_fields', {group_fields}, ...
    'target_ns_grid', target_ns_grid, ...
    'output_value_field', local_detect_output_value_field(source_table, options), ...
    'raw_value_field', char(string(local_getfield_or(options, 'raw_value_field', 'pass_ratio'))));
[view_table, dense_meta] = rebuild_mb_passratio_dense_view_table(source_table, search_domain, dense_options);
view_table = local_apply_recompute_mode(view_table, recompute_mode);
view_table = local_sort_view_table(view_table, group_fields, ns_field);
view_meta = local_apply_dense_meta(view_meta, dense_meta, policy);
view_meta.view_table_min_ns = local_min_or_nan(local_get_column(view_table, ns_field));
view_meta.view_table_max_ns = local_max_or_nan(local_get_column(view_table, ns_field));
view_meta.pass_fail = logical(local_getfield_or(dense_meta, 'pass_fail', false));
if view_meta.pass_fail
    view_meta.root_cause_tag = "correct";
else
    view_meta.root_cause_tag = "source_table_tail_only";
end
end

function [view_table, view_meta] = local_build_frontier_zoom_view(source_table, raw_eval_table, effective_dense_table, search_domain, ns_field, group_fields, recompute_mode, effective_window, plot_window, ns_step, options, view_meta, policy)
effective_meta = struct();
if ~isempty(effective_dense_table)
    dense_table = effective_dense_table;
    effective_meta = struct('dense_rebuild_used', true, 'inherited_from_effective_dense', true, 'zero_padding_used', false, 'sparse_projection_used', false, 'source_table_kind', "effective_dense_table", 'pass_fail', true);
else
    [dense_table, effective_meta] = local_build_dense_effective_view( ...
        source_table, raw_eval_table, search_domain, ns_field, group_fields, recompute_mode, effective_window, ns_step, options, view_meta, policy);
end
view_table = local_filter_ns_window(dense_table, ns_field, plot_window);
view_table = local_sort_view_table(view_table, group_fields, ns_field);
view_meta = local_apply_dense_meta(view_meta, effective_meta, policy);
view_meta.view_table_min_ns = local_min_or_nan(local_get_column(view_table, ns_field));
view_meta.view_table_max_ns = local_max_or_nan(local_get_column(view_table, ns_field));
view_meta.pass_fail = ~isempty(view_table) && any(isfinite(local_get_primary_passratio_column(view_table)));
view_meta.inherited_from_effective_dense = ~isempty(effective_dense_table) || logical(local_getfield_or(effective_meta, 'inherited_from_effective_dense', false));
if view_meta.pass_fail
    view_meta.root_cause_tag = "correct";
else
    view_meta.root_cause_tag = "source_table_tail_only";
end
end

function [view_table, view_meta] = local_build_global_full_replay_view(source_table, raw_eval_table, search_domain, ns_field, group_fields, recompute_mode, initial_ns_min, final_ns_max, ns_step, options, view_meta, policy)
grid_options = struct( ...
    'initial_ns_min', initial_ns_min, ...
    'final_ns_max', final_ns_max, ...
    'ns_step', ns_step, ...
    'origin_mode', string(local_getfield_or(options, 'history_origin', "initial_ns_min")));
[target_ns_grid, grid_meta] = build_mb_global_full_dense_ns_grid(search_domain, source_table, ns_field, grid_options);

dense_options = struct( ...
    'raw_eval_table', raw_eval_table, ...
    'ns_field', ns_field, ...
    'group_fields', {group_fields}, ...
    'target_ns_grid', target_ns_grid, ...
    'output_value_field', local_detect_output_value_field(source_table, options), ...
    'raw_value_field', char(string(local_getfield_or(options, 'raw_value_field', 'pass_ratio'))), ...
    'rebuild_scope', 'global_full', ...
    'initial_ns_min', grid_meta.initial_ns_min, ...
    'final_ns_max', grid_meta.final_ns_max, ...
    'ns_step', grid_meta.ns_step, ...
    'origin_mode', string(local_getfield_or(options, 'history_origin', "initial_ns_min")));
[view_table, dense_meta] = rebuild_mb_passratio_global_replay_table(source_table, search_domain, dense_options);
view_table = local_apply_recompute_mode(view_table, recompute_mode);
view_table = local_sort_view_table(view_table, group_fields, ns_field);
view_meta = local_apply_dense_meta(view_meta, dense_meta, policy);
    view_meta.domain_view = "global_full_replay";
    view_meta.view_table_min_ns = local_min_or_nan(local_get_column(view_table, ns_field));
    view_meta.view_table_max_ns = local_max_or_nan(local_get_column(view_table, ns_field));
    view_meta.history_padding_applied = false;
view_meta.pass_fail = logical(local_getfield_or(dense_meta, 'pass_fail', false));
if view_meta.pass_fail
    view_meta.root_cause_tag = "correct";
else
    view_meta.root_cause_tag = "source_table_tail_only";
end
end

function view_meta = local_apply_dense_meta(view_meta, dense_meta, policy)
view_meta.history_padding_applied = false;
view_meta.history_fill_mode = "none";
view_meta.zero_padding_used = logical(local_getfield_or(dense_meta, 'zero_padding_used', false));
view_meta.sparse_projection_used = logical(local_getfield_or(dense_meta, 'sparse_projection_used', false));
view_meta.dense_rebuild_used = logical(local_getfield_or(dense_meta, 'dense_rebuild_used', false));
view_meta.inherited_from_effective_dense = logical(local_getfield_or(dense_meta, 'inherited_from_effective_dense', false));
view_meta.source_table_kind = string(local_getfield_or(dense_meta, 'source_table_kind', ""));
view_meta.num_unique_ns_plotted = double(local_getfield_or(dense_meta, 'num_unique_ns_plotted', NaN));
view_meta.num_nonzero_rows = double(local_getfield_or(dense_meta, 'num_nonzero_rows', NaN));
view_meta.rebuild_scope = string(local_getfield_or(dense_meta, 'rebuild_scope', ""));
view_meta.dense_grid_min_ns = double(local_getfield_or(dense_meta, 'dense_grid_min_ns', NaN));
view_meta.dense_grid_max_ns = double(local_getfield_or(dense_meta, 'dense_grid_max_ns', NaN));
view_meta.dense_grid_step = double(local_getfield_or(dense_meta, 'dense_grid_step', NaN));
view_meta.num_dense_rows = double(local_getfield_or(dense_meta, 'num_dense_rows', NaN));
view_meta.num_raw_rows = double(local_getfield_or(dense_meta, 'num_raw_rows', NaN));
view_meta.num_recomputed_rows = double(local_getfield_or(dense_meta, 'num_recomputed_rows', NaN));
view_meta.allow_sparse_projection = logical(local_getfield_or(policy, 'allow_sparse_projection', false));
view_meta.allow_zero_padding = logical(local_getfield_or(policy, 'allow_zero_padding', false));
end

function output_field = local_detect_output_value_field(source_table, options)
value_fields = cellstr(string(local_getfield_or(options, 'value_fields', {})));
if ~isempty(value_fields) && istable(source_table) && ismember(value_fields{1}, source_table.Properties.VariableNames)
    output_field = value_fields{1};
    return;
end
candidates = {'max_pass_ratio', 'overlay_pass_ratio', 'max_pass_ratio_legacyDG', 'max_pass_ratio_closedD'};
for idx = 1:numel(candidates)
    if istable(source_table) && ismember(candidates{idx}, source_table.Properties.VariableNames)
        output_field = candidates{idx};
        return;
    end
end
output_field = 'max_pass_ratio';
end

function values = local_get_primary_passratio_column(T)
for field_name = ["max_pass_ratio", "overlay_pass_ratio", "max_pass_ratio_legacyDG", "max_pass_ratio_closedD"]
    if istable(T) && ismember(field_name, string(T.Properties.VariableNames))
        values = T.(char(field_name));
        return;
    end
end
values = [];
end

function filtered = local_filter_ns_window(T, ns_field, window)
filtered = T;
if isempty(T) || ~local_has_valid_window(window) || ~ismember(ns_field, T.Properties.VariableNames)
    return;
end
mask = isfinite(T.(ns_field)) & T.(ns_field) >= window(1) & T.(ns_field) <= window(2);
filtered = T(mask, :);
end

function tf = local_has_valid_window(window)
tf = isnumeric(window) && numel(window) >= 2 && all(isfinite(window(1:2))) && window(1) <= window(2);
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
if isempty(joined)
    return;
end
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

function summary_row = local_build_padding_summary_row(figure_name, height_km, group_row, group_fields, initial_ns_min, final_ns_max, num_original_points, num_padded_points, history_fill_mode, history_origin_mode, history_padding_applied, pass_fail)
summary_row = table( ...
    string(figure_name), ...
    double(height_km), ...
    string(local_group_key(group_row, group_fields)), ...
    double(initial_ns_min), ...
    double(final_ns_max), ...
    double(num_original_points), ...
    double(num_padded_points), ...
    string(history_fill_mode), ...
    string(history_origin_mode), ...
    logical(history_padding_applied), ...
    logical(history_padding_applied), ...
    logical(pass_fail), ...
    'VariableNames', {'figure_name', 'height_km', 'group_key', 'initial_ns_min', 'final_ns_max', 'num_original_points', 'num_padded_points', 'history_fill_mode', 'history_origin_mode', 'history_padding_applied', 'padding_applied', 'pass_fail'});
end

function height_km = local_group_height_km(T)
height_km = NaN;
if isempty(T)
    return;
end
if ismember('h_km', T.Properties.VariableNames)
    values = T.h_km(isfinite(T.h_km));
elseif ismember('height_km', T.Properties.VariableNames)
    values = T.height_km(isfinite(T.height_km));
else
    values = [];
end
if ~isempty(values)
    height_km = values(1);
end
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
mask = local_group_mask(T, group_row, group_fields);
filtered = T(mask, :);
end

function mask = local_group_mask(T, group_row, group_fields)
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

function T = local_sort_view_table(T, group_fields, ns_field)
if isempty(T)
    return;
end
sort_fields = [{ns_field}];
if ~isempty(group_fields)
    sort_fields = [group_fields(:).', {ns_field}];
end
sort_fields = unique(sort_fields, 'stable');
T = sortrows(T, sort_fields);
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

function domain_view = local_normalize_domain_view(domain_view)
domain_view = string(domain_view);
switch lower(strrep(strrep(char(domain_view), '-', '_'), ' ', '_'))
    case {'history_full', 'history'}
        domain_view = "history_full";
    case {'effective_full_range', 'effective', 'effective_range'}
        domain_view = "effective_full_range";
    case {'frontier_zoom', 'zoom'}
        domain_view = "frontier_zoom";
    case {'global_full_replay', 'global_replay', 'global_full_dense', 'global_dense'}
        domain_view = "global_full_replay";
    otherwise
        error('build_mb_passratio_domain_view:InvalidDomainView', ...
            'Unsupported domain_view: %s', char(domain_view));
end
end

function T = local_empty_padding_summary()
T = table('Size', [0, 12], ...
    'VariableTypes', {'string', 'double', 'string', 'double', 'double', 'double', 'double', 'string', 'string', 'logical', 'logical', 'logical'}, ...
    'VariableNames', {'figure_name', 'height_km', 'group_key', 'initial_ns_min', 'final_ns_max', 'num_original_points', 'num_padded_points', 'history_fill_mode', 'history_origin_mode', 'history_padding_applied', 'padding_applied', 'pass_fail'});
end
