function tune_result = autotune_mb_passratio_plot_window(profile, phasecurve_table, options)
%AUTOTUNE_MB_PASSRATIO_PLOT_WINDOW Iteratively tune MB pass-ratio search/plot windows with cache reuse.

if nargin < 1 || isempty(profile)
    profile = get_mb_search_profile('mb_auto_plot_tune');
end
if nargin < 2 || isempty(phasecurve_table)
    phasecurve_table = table();
end
if nargin < 3 || isempty(options)
    options = struct();
end

profile = merge_mb_search_profile_overrides(get_mb_search_profile(profile), struct(), "");
auto_tune = local_getfield_or(options, 'auto_tune', local_getfield_or(profile, 'auto_tune', struct()));
cache_cfg = local_getfield_or(options, 'cache', local_getfield_or(profile, 'cache', struct()));
cache_dir = char(string(local_getfield_or(options, 'cache_dir', fullfile(pwd, 'cache', 'mb_passratio_autotune'))));
ensure_dir(cache_dir);
evaluator_fn = local_getfield_or(options, 'evaluator_fn', []);
max_iterations = max(1, local_getfield_or(auto_tune, 'max_iterations', 5));
reuse_tune_cache = logical(local_getfield_or(cache_cfg, 'reuse_tune_cache', true));

current_profile = profile;
current_phasecurve = phasecurve_table;
history = repmat(local_empty_history_entry(), max_iterations, 1);
history_count = 0;
cache_hits = 0;
fresh_evaluations = 0;
best_score = -inf;
best_entry = local_empty_history_entry();
state = "limit_reached";
stop_reason = "limit_reached_without_right_plateau";
stop_reason_detail = "Reached the maximum number of auto-tune iterations.";

for iter = 1:max_iterations
    [score_result, current_phasecurve, cache_hit, was_evaluated] = local_evaluate_profile( ...
        current_profile, current_phasecurve, options, evaluator_fn, cache_dir, reuse_tune_cache, auto_tune, cache_cfg);
    cache_hits = cache_hits + double(cache_hit);
    fresh_evaluations = fresh_evaluations + double(was_evaluated);

    history_count = history_count + 1;
    history(history_count, 1) = local_build_history_entry(iter, current_profile, score_result, cache_hit, was_evaluated, "initial_eval");
    if score_result.score > best_score
        best_score = score_result.score;
        best_entry = history(history_count, 1);
        best_entry.phasecurve_table = current_phasecurve;
    end

    decision = should_expand_mb_search_profile(current_profile, score_result.quality, history(1:history_count), auto_tune);
    history(history_count, 1).state = string(decision.state);
    history(history_count, 1).stop_reason = string(decision.reason);
    history(history_count, 1).stop_reason_detail = string(local_getfield_or(decision, 'reason_detail', ""));
    if ~decision.should_expand
        state = string(decision.state);
        stop_reason = string(decision.reason);
        stop_reason_detail = string(local_getfield_or(decision, 'reason_detail', ""));
        break;
    end

    [next_profile, action] = update_mb_search_profile_iteratively(current_profile, score_result.quality, auto_tune);
    if local_profiles_equivalent(current_profile, next_profile)
        state = "stalled";
        stop_reason = string(local_getfield_or(score_result, 'reason_code', "limit_reached_insufficient_transition"));
        stop_reason_detail = "The iterative auto-tune update did not change the search profile.";
        history(history_count, 1).state = state;
        history(history_count, 1).stop_reason = stop_reason;
        history(history_count, 1).stop_reason_detail = stop_reason_detail;
        break;
    end

    history(history_count, 1).action = string(action.name);
    history(history_count, 1).action_reason = string(action.reason);
    preserve_phasecurve = local_same_search_grid(current_profile, next_profile);
    current_profile = next_profile;
    if ~preserve_phasecurve
        current_phasecurve = table();
    end
end

history = history(1:history_count, 1);
iteration_history = local_history_to_table(history);
if isempty(iteration_history)
    iteration_history = table();
end

tune_result = struct();
tune_result.profile_name = string(local_getfield_or(profile, 'name', "mb_auto_plot_tune"));
tune_result.semantic_mode = string(local_getfield_or(options, 'semantic_mode', local_getfield_or(profile, 'semantic_mode', "legacyDG")));
tune_result.sensor_group = string(local_getfield_or(options, 'sensor_group', local_first_sensor_group(profile)));
tune_result.height_km = local_getfield_or(options, 'height_km', local_first_height(profile));
tune_result.auto_tune_mode = string(local_getfield_or(auto_tune, 'mode', "iterative_recommend_only"));
tune_result.recommended_P_grid = reshape(local_getfield_or(best_entry.profile, 'P_values', local_getfield_or(best_entry.profile, 'P_grid', local_getfield_or(profile, 'P_values', []))), 1, []);
tune_result.recommended_T_grid = reshape(local_getfield_or(best_entry.profile, 'T_values', local_getfield_or(best_entry.profile, 'T_grid', local_getfield_or(profile, 'T_values', []))), 1, []);
tune_result.recommended_plot_xlim_ns = reshape(local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'recommended_xlim_ns', ...
    local_getfield_or(best_entry.profile, 'Ns_xlim_plot', local_getfield_or(best_entry.profile, 'plot_xlim_ns', local_getfield_or(profile, 'Ns_xlim_plot', [])))), 1, []);
tune_result.recommended_search_ns_min = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), ...
    'recommended_search_ns_min', local_grid_ns_bound(tune_result.recommended_P_grid, tune_result.recommended_T_grid, 'min'));
tune_result.recommended_search_ns_max = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), ...
    'recommended_search_ns_max', local_grid_ns_bound(tune_result.recommended_P_grid, tune_result.recommended_T_grid, 'max'));
tune_result.recommended_reason = string(local_getfield_or(best_entry, 'action_reason', local_getfield_or(best_entry.score_result, 'reason', "")));
tune_result.best_score = best_score;
tune_result.best_candidate_name = sprintf('iter_%02d_%s', local_getfield_or(best_entry, 'iteration', 1), char(local_getfield_or(best_entry, 'action', "initial_eval")));
tune_result.best_phasecurve_table = local_getfield_or(best_entry, 'phasecurve_table', phasecurve_table);
tune_result.candidate_table = iteration_history;
tune_result.iteration_history = iteration_history;
tune_result.transition_ns_low = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'transition_ns_low', NaN);
tune_result.transition_ns_high = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'transition_ns_high', NaN);
tune_result.state = string(state);
tune_result.stop_reason = string(stop_reason);
tune_result.final_stop_reason = string(stop_reason);
tune_result.stop_reason_detail = string(stop_reason_detail);
tune_result.unresolved_due_to_search_limit = strcmpi(char(string(state)), 'limit_reached');
tune_result.left_zero_score = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'left_zero_score', NaN);
tune_result.right_one_score = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'right_one_score', NaN);
tune_result.transition_center_score = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'transition_center_score', NaN);
tune_result.transition_width_score = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'transition_width_score', NaN);
tune_result.saturation_score = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'saturation_score', NaN);
tune_result.num_curves_saturated = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'num_curves_saturated', 0);
tune_result.num_curves_with_transition = local_getfield_or(local_getfield_or(best_entry, 'score_result', struct()), 'num_curves_with_transition', 0);
tune_result.stats = struct( ...
    'cache_hits', cache_hits, ...
    'fresh_evaluations', fresh_evaluations, ...
    'total_iterations', history_count, ...
    'cache_dir', string(cache_dir));

export_artifacts = export_mb_autotune_iteration_summary(tune_result, options);
if strlength(export_artifacts.history_csv) > 0
    tune_result.iteration_history_csv = export_artifacts.history_csv;
end
if strlength(export_artifacts.summary_csv) > 0
    tune_result.summary_csv = export_artifacts.summary_csv;
end
if ~isempty(export_artifacts.summary_row)
    tune_result.summary_row = export_artifacts.summary_row;
end
end

function [score_result, candidate_phasecurve, cache_hit, was_evaluated] = local_evaluate_profile(profile, current_phasecurve, options, evaluator_fn, cache_dir, reuse_tune_cache, auto_tune, cache_cfg)
semantic_mode = string(local_getfield_or(options, 'semantic_mode', local_getfield_or(profile, 'semantic_mode', "legacyDG")));
sensor_group = string(local_getfield_or(options, 'sensor_group', local_first_sensor_group(profile)));
height_km = local_getfield_or(options, 'height_km', local_first_height(profile));
cache_key = build_mb_eval_cache_key(struct( ...
    'purpose', "mb_passratio_autotune_iterative", ...
    'semantic_mode', semantic_mode, ...
    'sensor_group', sensor_group, ...
    'height_km', height_km, ...
    'P_grid', reshape(local_getfield_or(profile, 'P_values', local_getfield_or(profile, 'P_grid', [])), 1, []), ...
    'T_grid', reshape(local_getfield_or(profile, 'T_values', local_getfield_or(profile, 'T_grid', [])), 1, []), ...
    'plot_xlim_ns', reshape(local_getfield_or(profile, 'Ns_xlim_plot', local_getfield_or(profile, 'plot_xlim_ns', [])), 1, []), ...
    'cache_tag', string(local_getfield_or(cache_cfg, 'tag', "mb_auto_plot_tune"))));
cache_file = fullfile(cache_dir, sprintf('mb_passratio_autotune_%s.mat', char(cache_key)));

cache_hit = false;
was_evaluated = false;
candidate_phasecurve = current_phasecurve;

if reuse_tune_cache && isfile(cache_file)
    loaded = load(cache_file);
    if isfield(loaded, 'cached_result')
        cached = loaded.cached_result;
        candidate_phasecurve = local_getfield_or(cached, 'phasecurve_table', table());
        score_result = local_getfield_or(cached, 'score_result', struct());
        if local_score_result_needs_refresh(score_result)
            quality = check_mb_passratio_window_quality(candidate_phasecurve, local_getfield_or(profile, 'Ns_xlim_plot', local_getfield_or(profile, 'plot_xlim_ns', [])), auto_tune);
            score_result = compute_mb_autotune_iteration_score(profile, candidate_phasecurve, quality, auto_tune);
            cached_result = struct( ...
                'profile', profile, ...
                'phasecurve_table', candidate_phasecurve, ...
                'score_result', score_result);
            save(cache_file, 'cached_result');
        end
        cache_hit = true;
        return;
    end
end

needs_fresh_eval = isempty(candidate_phasecurve) || ~ismember('Ns', candidate_phasecurve.Properties.VariableNames);
if needs_fresh_eval
    if isa(evaluator_fn, 'function_handle')
        candidate_phasecurve = evaluator_fn(profile);
        was_evaluated = true;
    else
        candidate_phasecurve = table();
    end
end

quality = check_mb_passratio_window_quality(candidate_phasecurve, local_getfield_or(profile, 'Ns_xlim_plot', local_getfield_or(profile, 'plot_xlim_ns', [])), auto_tune);
score_result = compute_mb_autotune_iteration_score(profile, candidate_phasecurve, quality, auto_tune);

cached_result = struct( ...
    'profile', profile, ...
    'phasecurve_table', candidate_phasecurve, ...
    'score_result', score_result);
save(cache_file, 'cached_result');
end

function entry = local_build_history_entry(iteration, profile, score_result, cache_hit, was_evaluated, action_name)
entry = local_empty_history_entry();
entry.iteration = iteration;
entry.profile = profile;
entry.score_result = score_result;
entry.cache_hit = logical(cache_hit);
entry.was_evaluated = logical(was_evaluated);
entry.action = string(action_name);
entry.action_reason = string(local_getfield_or(score_result, 'reason', ""));
end

function entry = local_empty_history_entry()
entry = struct( ...
    'iteration', 0, ...
    'profile', struct(), ...
    'score_result', struct(), ...
    'cache_hit', false, ...
    'was_evaluated', false, ...
    'action', "", ...
    'action_reason', "", ...
    'state', "", ...
    'stop_reason', "", ...
    'stop_reason_detail', "", ...
    'phasecurve_table', table());
end

function history_table = local_history_to_table(history)
if isempty(history)
    history_table = table();
    return;
end

row_cells = cell(numel(history), 1);
for idx = 1:numel(history)
    h = history(idx);
    q = local_getfield_or(h.score_result, 'quality', struct());
    row_cells{idx, 1} = table( ...
        h.iteration, ...
        string(h.action), ...
        string(h.action_reason), ...
        string(h.state), ...
        string(h.stop_reason), ...
        string(h.stop_reason_detail), ...
        logical(h.cache_hit), ...
        logical(h.was_evaluated), ...
        local_getfield_or(h.score_result, 'score', NaN), ...
        local_getfield_or(q, 'left_zero_score', NaN), ...
        local_getfield_or(q, 'right_one_score', NaN), ...
        local_getfield_or(q, 'transition_center_score', NaN), ...
        local_getfield_or(q, 'transition_width_score', NaN), ...
        local_getfield_or(q, 'saturation_score', NaN), ...
        local_getfield_or(q, 'monotonicity_soft_score', NaN), ...
        local_getfield_or(q, 'plateau_score', NaN), ...
        local_getfield_or(q, 'domain_efficiency_penalty', NaN), ...
        logical(local_getfield_or(q, 'left_zero_reached', false)), ...
        logical(local_getfield_or(q, 'right_plateau_reached', false)), ...
        logical(local_getfield_or(q, 'mid_transition_ok', false)), ...
        logical(local_getfield_or(q, 'transition_width_ok', false)), ...
        logical(local_getfield_or(q, 'full_transition_resolved', false)), ...
        logical(local_getfield_or(q, 'no_feasible_point_found', false)), ...
        logical(local_getfield_or(q, 'only_single_point_visible', false)), ...
        logical(local_getfield_or(q, 'insufficient_valid_curves', false)), ...
        local_getfield_or(q, 'transition_ns_low_median', NaN), ...
        local_getfield_or(q, 'transition_ns_high_median', NaN), ...
        local_getfield_or(q, 'final_passratio_median', NaN), ...
        local_getfield_or(q, 'num_curves_saturated', 0), ...
        local_getfield_or(q, 'num_curves_with_transition', 0), ...
        local_getfield_or(q, 'recommended_search_ns_min', NaN), ...
        local_getfield_or(q, 'recommended_search_ns_max', NaN), ...
        string(mat2str(reshape(local_getfield_or(h.profile, 'P_values', local_getfield_or(h.profile, 'P_grid', [])), 1, []))), ...
        string(mat2str(reshape(local_getfield_or(h.profile, 'T_values', local_getfield_or(h.profile, 'T_grid', [])), 1, []))), ...
        string(mat2str(reshape(local_getfield_or(h.profile, 'Ns_xlim_plot', local_getfield_or(h.profile, 'plot_xlim_ns', [])), 1, []))), ...
        'VariableNames', { ...
            'iteration', 'action', 'action_reason', 'state', 'stop_reason', 'stop_reason_detail', 'cache_hit', 'was_evaluated', ...
            'score', 'left_zero_score', 'right_one_score', 'transition_center_score', ...
            'transition_width_score', 'saturation_score', 'monotonicity_soft_score', 'plateau_score', ...
            'domain_efficiency_penalty', 'left_zero_reached', 'right_plateau_reached', 'mid_transition_ok', ...
            'transition_width_ok', 'full_transition_resolved', 'no_feasible_point_found', ...
            'only_single_point_visible', 'insufficient_valid_curves', 'transition_ns_low', 'transition_ns_high', ...
            'final_passratio_median', 'num_curves_saturated', 'num_curves_with_transition', ...
            'recommended_search_ns_min', 'recommended_search_ns_max', 'P_grid', 'T_grid', 'plot_xlim_ns'});
end
history_table = vertcat(row_cells{:});
end

function tf = local_profiles_equivalent(a, b)
tf = isequal(reshape(local_getfield_or(a, 'P_values', local_getfield_or(a, 'P_grid', [])), 1, []), ...
             reshape(local_getfield_or(b, 'P_values', local_getfield_or(b, 'P_grid', [])), 1, [])) && ...
     isequal(reshape(local_getfield_or(a, 'T_values', local_getfield_or(a, 'T_grid', [])), 1, []), ...
             reshape(local_getfield_or(b, 'T_values', local_getfield_or(b, 'T_grid', [])), 1, [])) && ...
     isequal(reshape(local_getfield_or(a, 'Ns_xlim_plot', local_getfield_or(a, 'plot_xlim_ns', [])), 1, []), ...
             reshape(local_getfield_or(b, 'Ns_xlim_plot', local_getfield_or(b, 'plot_xlim_ns', [])), 1, []));
end

function tf = local_same_search_grid(a, b)
tf = isequal(reshape(local_getfield_or(a, 'P_values', local_getfield_or(a, 'P_grid', [])), 1, []), ...
             reshape(local_getfield_or(b, 'P_values', local_getfield_or(b, 'P_grid', [])), 1, [])) && ...
     isequal(reshape(local_getfield_or(a, 'T_values', local_getfield_or(a, 'T_grid', [])), 1, []), ...
             reshape(local_getfield_or(b, 'T_values', local_getfield_or(b, 'T_grid', [])), 1, []));
end

function group = local_first_sensor_group(profile_like)
groups = cellstr(string(local_getfield_or(profile_like, 'sensor_group_names', {'baseline'})));
group = groups{1};
end

function height_km = local_first_height(profile_like)
heights = reshape(local_getfield_or(profile_like, 'height_grid_km', NaN), 1, []);
height_km = heights(1);
end

function ns_value = local_grid_ns_bound(P_grid, T_grid, mode)
if isempty(P_grid) || isempty(T_grid)
    ns_value = NaN;
    return;
end
switch lower(mode)
    case 'min'
        ns_value = min(P_grid) * min(T_grid);
    otherwise
        ns_value = max(P_grid) * max(T_grid);
end
end

function tf = local_score_result_needs_refresh(score_result)
quality = local_getfield_or(score_result, 'quality', struct());
tf = ~isfield(score_result, 'reason_code') || ~isfield(score_result, 'recommended_search_ns_min') || ...
    ~isfield(quality, 'no_feasible_point_found') || ~isfield(quality, 'transition_width_score');
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
