function decision = should_expand_mb_search_profile(profile, quality, history, options)
%SHOULD_EXPAND_MB_SEARCH_PROFILE Decide whether iterative auto-tune should continue expanding the search domain.

if nargin < 4 || isempty(options)
    options = struct();
end

search_domain = struct( ...
    'P_grid', reshape(local_getfield_or(profile, 'P_values', local_getfield_or(profile, 'P_grid', [])), 1, []), ...
    'T_grid', reshape(local_getfield_or(profile, 'T_values', local_getfield_or(profile, 'T_grid', [])), 1, []));
decision = should_expand_mb_search_domain(search_domain, quality, history, options);
if ~strcmpi(char(string(local_getfield_or(options, 'mode', "iterative_recommend_only"))), 'evaluate_only')
    return;
end

decision = struct( ...
    'should_expand', true, ...
    'state', "continue", ...
    'reason', "continue_search", ...
    'reason_detail', "Quality target not reached yet.", ...
    'limiting_factor', "", ...
    'stagnated', false);

if quality.full_transition_resolved
    decision.should_expand = false;
    decision.state = "success";
    decision.reason = "success_balanced_window";
    decision.reason_detail = "Quality thresholds reached: left floor, right plateau, centered transition, and adequate transition width are all satisfied.";
    return;
end

mode = lower(char(string(local_getfield_or(options, 'mode', "iterative_recommend_only"))));
if strcmp(mode, 'evaluate_only')
    decision.should_expand = false;
    decision.state = "evaluated_only";
    decision.reason = local_quality_stop_code(quality);
    decision.reason_detail = "Evaluate-only auto-tune mode scored the current domain without iterative expansion.";
    return;
end

iteration_idx = numel(history);
max_iterations = local_getfield_or(options, 'max_iterations', 5);
if iteration_idx >= max_iterations
    decision.should_expand = false;
    decision.state = "limit_reached";
    decision.reason = local_quality_stop_code(quality);
    decision.reason_detail = "Reached the maximum number of auto-tune iterations.";
    decision.limiting_factor = "max_iterations";
    return;
end

if iteration_idx >= 2
    score_delta = local_history_score(history(end)) - local_history_score(history(end - 1));
    if abs(score_delta) < 0.5
        if local_profiles_equivalent(history(end).profile, history(end - 1).profile)
            decision.should_expand = false;
            decision.state = "stalled";
            decision.reason = local_quality_stop_code(quality);
            decision.reason_detail = "The best search profile stopped changing and score improvement is below threshold.";
            decision.stagnated = true;
            return;
        end
    end
end

can_expand_right = max(profile.T_values) < local_getfield_or(options, 'max_T', max(profile.T_values)) || ...
    max(profile.P_values) < local_getfield_or(options, 'max_P', max(profile.P_values));
can_expand_left = min(profile.T_values) > 2 || min(profile.P_values) > 2;

if ~quality.right_plateau_reached && ~can_expand_right
    decision.should_expand = false;
    decision.state = "limit_reached";
    decision.reason = "limit_reached_without_right_plateau";
    decision.reason_detail = "The right-side unity plateau was not reached before hitting the configured P/T upper limits.";
    decision.limiting_factor = "search_upper_bound";
    return;
end

if ~quality.left_zero_reached && ~can_expand_left
    decision.should_expand = false;
    decision.state = "limit_reached";
    decision.reason = "limit_reached_insufficient_transition";
    decision.reason_detail = "The left-side near-zero floor was not reached before hitting the configured P/T lower limits.";
    decision.limiting_factor = "search_lower_bound";
    return;
end
end

function code = local_quality_stop_code(quality)
if quality.no_feasible_point_found
    code = "no_feasible_point_found";
elseif quality.only_single_point_visible
    code = "only_single_point_visible";
elseif quality.insufficient_valid_curves
    code = "insufficient_valid_curves";
elseif ~quality.right_plateau_reached
    code = "limit_reached_without_right_plateau";
elseif quality.full_transition_resolved
    code = "success_balanced_window";
else
    code = "limit_reached_insufficient_transition";
end
end

function tf = local_profiles_equivalent(a, b)
tf = isequal(reshape(local_getfield_or(a, 'P_values', local_getfield_or(a, 'P_grid', [])), 1, []), ...
             reshape(local_getfield_or(b, 'P_values', local_getfield_or(b, 'P_grid', [])), 1, [])) && ...
     isequal(reshape(local_getfield_or(a, 'T_values', local_getfield_or(a, 'T_grid', [])), 1, []), ...
             reshape(local_getfield_or(b, 'T_values', local_getfield_or(b, 'T_grid', [])), 1, [])) && ...
     isequal(reshape(local_getfield_or(a, 'Ns_xlim_plot', local_getfield_or(a, 'plot_xlim_ns', [])), 1, []), ...
             reshape(local_getfield_or(b, 'Ns_xlim_plot', local_getfield_or(b, 'plot_xlim_ns', [])), 1, []));
end

function score = local_history_score(entry)
score = local_getfield_or(local_getfield_or(entry, 'score_result', struct()), 'score', -inf);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
