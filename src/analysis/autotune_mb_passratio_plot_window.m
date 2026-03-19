function tune_result = autotune_mb_passratio_plot_window(profile, phasecurve_table, options)
%AUTOTUNE_MB_PASSRATIO_PLOT_WINDOW Heuristically recommend a better MB pass-ratio plot/search window.

if nargin < 1 || isempty(profile)
    profile = get_mb_search_profile('mb_auto_plot_tune');
end
if nargin < 2 || isempty(phasecurve_table)
    phasecurve_table = table();
end
if nargin < 3 || isempty(options)
    options = struct();
end

auto_tune = local_getfield_or(options, 'auto_tune', local_getfield_or(profile, 'auto_tune', struct()));
cache_cfg = local_getfield_or(options, 'cache', local_getfield_or(profile, 'cache', struct()));
cache_dir = char(string(local_getfield_or(options, 'cache_dir', fullfile(pwd, 'cache', 'mb_passratio_autotune'))));
ensure_dir(cache_dir);

candidates = propose_mb_search_expansion_candidates(profile, phasecurve_table, struct('auto_tune', auto_tune));
max_iterations = local_getfield_or(auto_tune, 'max_iterations', 1);
max_candidates = min(numel(candidates), local_getfield_or(auto_tune, 'max_candidate_count', numel(candidates)));
reuse_tune_cache = logical(local_getfield_or(cache_cfg, 'reuse_tune_cache', true));
evaluator_fn = local_getfield_or(options, 'evaluator_fn', []);

candidate_rows = cell(max_candidates, 1);
row_count = 0;
best_score = -inf;
best_candidate = struct();
best_phasecurve = table();
best_score_result = struct();
cache_hits = 0;
evaluated_count = 0;
stop_reason = "candidate budget exhausted";

iteration_limit = max(1, min(max_iterations, max_candidates));
for idx = 1:max_candidates
    candidate = candidates(idx);
    if idx > iteration_limit && candidate.requires_search_expansion
        continue;
    end

    [score_result, candidate_phasecurve, cache_hit, was_evaluated] = local_score_candidate( ...
        candidate, phasecurve_table, options, evaluator_fn, cache_dir, reuse_tune_cache, auto_tune, cache_cfg);
    cache_hits = cache_hits + double(cache_hit);
    evaluated_count = evaluated_count + double(was_evaluated);
    row_count = row_count + 1;
    candidate_rows{row_count, 1} = local_candidate_row(candidate, score_result, cache_hit, was_evaluated);

    if score_result.score > best_score
        best_score = score_result.score;
        best_candidate = candidate;
        best_phasecurve = candidate_phasecurve;
        best_score_result = score_result;
    end

    if local_stop_criteria_met(score_result, auto_tune)
        stop_reason = "target low/high coverage and centered transition achieved";
        break;
    end
end

if row_count == 0
    candidate_table = table();
else
    candidate_table = vertcat(candidate_rows{1:row_count});
    candidate_table = sortrows(candidate_table, {'score', 'candidate_name'}, {'descend', 'ascend'});
end

tune_result = struct();
tune_result.profile_name = string(local_getfield_or(profile, 'name', "mb_auto_plot_tune"));
tune_result.semantic_mode = string(local_getfield_or(options, 'semantic_mode', local_getfield_or(profile, 'semantic_mode', "legacyDG")));
tune_result.sensor_group = string(local_getfield_or(options, 'sensor_group', local_first_sensor_group(profile)));
tune_result.height_km = local_getfield_or(options, 'height_km', NaN);
tune_result.recommended_P_grid = reshape(local_getfield_or(best_candidate, 'P_grid', local_getfield_or(profile, 'P_grid', [])), 1, []);
tune_result.recommended_T_grid = reshape(local_getfield_or(best_candidate, 'T_grid', local_getfield_or(profile, 'T_grid', [])), 1, []);
tune_result.recommended_plot_xlim_ns = reshape(local_getfield_or(best_candidate, 'plot_xlim_ns', local_getfield_or(profile, 'plot_xlim_ns', [])), 1, []);
tune_result.recommended_reason = string(local_getfield_or(best_candidate, 'reason', ""));
tune_result.best_score = best_score;
tune_result.best_candidate_name = string(local_getfield_or(best_candidate, 'name', ""));
tune_result.best_phasecurve_table = best_phasecurve;
tune_result.candidate_table = candidate_table;
tune_result.transition_ns_low = local_getfield_or(best_score_result, 'transition_ns_low', NaN);
tune_result.transition_ns_high = local_getfield_or(best_score_result, 'transition_ns_high', NaN);
tune_result.stop_reason = string(stop_reason);
tune_result.stats = struct( ...
    'cache_hits', cache_hits, ...
    'evaluated_candidates', evaluated_count, ...
    'candidate_count', row_count, ...
    'cache_dir', string(cache_dir));
end

function [score_result, candidate_phasecurve, cache_hit, was_evaluated] = local_score_candidate(candidate, current_phasecurve, options, evaluator_fn, cache_dir, reuse_tune_cache, auto_tune, cache_cfg)
semantic_mode = string(local_getfield_or(options, 'semantic_mode', candidate.semantic_mode));
sensor_group = string(local_getfield_or(options, 'sensor_group', local_first_sensor_group(candidate)));
height_km = local_getfield_or(options, 'height_km', local_first_height(candidate));
cache_key = build_mb_eval_cache_key(struct( ...
    'purpose', "mb_passratio_autotune", ...
    'semantic_mode', semantic_mode, ...
    'sensor_group', sensor_group, ...
    'height_km', height_km, ...
    'P_grid', reshape(candidate.P_grid, 1, []), ...
    'T_grid', reshape(candidate.T_grid, 1, []), ...
    'plot_xlim_ns', reshape(candidate.plot_xlim_ns, 1, []), ...
    'cache_tag', string(local_getfield_or(cache_cfg, 'tag', "mb_auto_plot_tune"))));
cache_file = fullfile(cache_dir, sprintf('mb_passratio_autotune_%s.mat', char(cache_key)));

cache_hit = false;
was_evaluated = false;
candidate_phasecurve = current_phasecurve;

if reuse_tune_cache && isfile(cache_file)
    loaded = load(cache_file);
    if isfield(loaded, 'cached_result')
        cached = loaded.cached_result;
        score_result = cached.score_result;
        candidate_phasecurve = cached.phasecurve_table;
        cache_hit = true;
        return;
    end
end

if candidate.requires_search_expansion
    if isa(evaluator_fn, 'function_handle')
        candidate_phasecurve = evaluator_fn(candidate);
        was_evaluated = true;
    else
        score_result = struct( ...
            'score', -inf, ...
            'has_low_region', false, ...
            'has_high_region', false, ...
            'transition_ns_low', NaN, ...
            'transition_ns_high', NaN, ...
            'transition_ns_mid', NaN, ...
            'window_mid', mean(candidate.plot_xlim_ns), ...
            'window_width', diff(candidate.plot_xlim_ns), ...
            'left_margin_ratio', NaN, ...
            'right_margin_ratio', NaN, ...
            'reason', "Candidate requires a search expansion, but no evaluator callback was provided.");
        return;
    end
end

score_result = score_mb_passratio_plot_window(candidate_phasecurve, candidate.plot_xlim_ns, auto_tune);

cached_result = struct( ...
    'candidate', candidate, ...
    'phasecurve_table', candidate_phasecurve, ...
    'score_result', score_result);
save(cache_file, 'cached_result');
end

function tf = local_stop_criteria_met(score_result, auto_tune)
target_center = local_getfield_or(auto_tune, 'target_transition_center', 0.50);
required_low_margin = local_getfield_or(auto_tune, 'required_low_margin', 0.10);
required_high_margin = local_getfield_or(auto_tune, 'required_high_margin', 0.10);
window_mid_ratio = (score_result.transition_ns_mid - (score_result.window_mid - score_result.window_width / 2)) / max(score_result.window_width, eps);
tf = score_result.has_low_region && score_result.has_high_region && ...
    abs(window_mid_ratio - target_center) <= 0.20 && ...
    score_result.left_margin_ratio >= required_low_margin && ...
    score_result.right_margin_ratio >= required_high_margin;
end

function row = local_candidate_row(candidate, score_result, cache_hit, was_evaluated)
row = table( ...
    string(candidate.name), ...
    string(candidate.reason), ...
    string(mat2str(candidate.P_grid)), ...
    string(mat2str(candidate.T_grid)), ...
    string(mat2str(candidate.plot_xlim_ns)), ...
    logical(candidate.requires_search_expansion), ...
    logical(cache_hit), ...
    logical(was_evaluated), ...
    score_result.score, ...
    score_result.transition_ns_low, ...
    score_result.transition_ns_high, ...
    string(score_result.reason), ...
    'VariableNames', {'candidate_name', 'candidate_reason', 'P_grid', 'T_grid', 'plot_xlim_ns', ...
    'requires_search_expansion', 'cache_hit', 'was_evaluated', 'score', ...
    'transition_ns_low', 'transition_ns_high', 'score_reason'});
end

function group = local_first_sensor_group(profile_like)
groups = cellstr(string(local_getfield_or(profile_like, 'sensor_group_names', {'baseline'})));
group = groups{1};
end

function height_km = local_first_height(profile_like)
heights = reshape(local_getfield_or(profile_like, 'height_grid_km', NaN), 1, []);
height_km = heights(1);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
