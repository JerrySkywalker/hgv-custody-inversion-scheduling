function artifacts = export_mb_autotune_iteration_summary(tune_result, options)
%EXPORT_MB_AUTOTUNE_ITERATION_SUMMARY Export MB auto-tune iteration history and summary helpers.

if nargin < 2 || isempty(options)
    options = struct();
end

artifacts = struct( ...
    'history_csv', "", ...
    'context_tag', "", ...
    'summary_row', table());

tables_dir = char(string(local_getfield_or(options, 'tables_dir', "")));
if strlength(string(tables_dir)) == 0
    return;
end
ensure_dir(tables_dir);

context_tag = local_context_tag(tune_result);
artifacts.context_tag = string(context_tag);

history_table = local_getfield_or(tune_result, 'iteration_history', table());
if ~isempty(history_table)
    history_csv = fullfile(tables_dir, sprintf('MB_autotune_iteration_history_%s.csv', context_tag));
    milestone_common_save_table(history_table, history_csv);
    artifacts.history_csv = string(history_csv);
end

stats = local_getfield_or(tune_result, 'stats', struct());
artifacts.summary_row = table( ...
    string(local_getfield_or(tune_result, 'profile_name', "")), ...
    string(local_getfield_or(tune_result, 'semantic_mode', "")), ...
    string(local_getfield_or(tune_result, 'sensor_group', "")), ...
    local_getfield_or(tune_result, 'height_km', NaN), ...
    string(local_getfield_or(tune_result, 'state', "")), ...
    string(local_getfield_or(tune_result, 'stop_reason', "")), ...
    logical(local_getfield_or(tune_result, 'unresolved_due_to_search_limit', false)), ...
    local_getfield_or(tune_result, 'best_score', NaN), ...
    local_getfield_or(stats, 'total_iterations', 0), ...
    local_getfield_or(stats, 'cache_hits', 0), ...
    local_getfield_or(stats, 'fresh_evaluations', 0), ...
    string(local_getfield_or(artifacts, 'history_csv', "")), ...
    'VariableNames', {'profile_name', 'semantic_mode', 'sensor_group', 'height_km', 'state', 'stop_reason', ...
    'unresolved_due_to_search_limit', 'best_score', 'total_iterations', 'cache_hits', 'fresh_evaluations', 'iteration_history_csv'});
end

function tag = local_context_tag(tune_result)
height_km = local_getfield_or(tune_result, 'height_km', NaN);
if isfinite(height_km)
    h_tag = sprintf('h%d', round(height_km));
else
    h_tag = 'hNA';
end
sensor_tag = char(matlab.lang.makeValidName(lower(char(string(local_getfield_or(tune_result, 'sensor_group', "baseline"))))));
semantic_tag = char(matlab.lang.makeValidName(lower(char(string(local_getfield_or(tune_result, 'semantic_mode', "legacyDG"))))));
profile_tag = char(matlab.lang.makeValidName(lower(char(string(local_getfield_or(tune_result, 'profile_name', "mb_auto_plot_tune"))))));
tag = sprintf('%s_%s_%s_%s', h_tag, sensor_tag, semantic_tag, profile_tag);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
