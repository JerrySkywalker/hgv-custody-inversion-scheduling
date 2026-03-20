function decision = should_expand_mb_search_domain(search_domain, quality, history, options)
%SHOULD_EXPAND_MB_SEARCH_DOMAIN Decide whether the search domain should expand.

if nargin < 4 || isempty(options)
    options = struct();
end

decision = struct( ...
    'should_expand', true, ...
    'state', "continue", ...
    'reason', "continue_search", ...
    'reason_detail', "Search-domain quality target not reached yet.", ...
    'limiting_factor', "", ...
    'stagnated', false);

if quality.full_transition_resolved
    decision.should_expand = false;
    decision.state = "success";
    decision.reason = "unity_plateau_reached";
    decision.reason_detail = "Search-domain diagnostics indicate that the transition band is now internally resolved.";
    return;
end

iteration_idx = numel(history);
max_iterations = local_getfield_or(options, 'max_iterations', 5);
if iteration_idx >= max_iterations
    decision.should_expand = false;
    decision.state = "limit_reached";
    decision.reason = local_limit_reason(quality);
    decision.reason_detail = "Reached the maximum number of incremental search expansions.";
    decision.limiting_factor = "max_iterations";
    return;
end

if iteration_idx >= 2
    score_delta = local_history_score(history(end)) - local_history_score(history(end - 1));
    if abs(score_delta) < 0.25 && local_domains_equivalent(history(end).profile, history(end - 1).profile)
        decision.should_expand = false;
        decision.state = "stalled";
        decision.reason = "boundary_dominated_but_budget_exhausted";
        decision.reason_detail = "The search-domain recommendation stopped changing while the score improvement stayed below threshold.";
        decision.stagnated = true;
        return;
    end
end

P_values = reshape(local_getfield_or(search_domain, 'P_grid', []), 1, []);
T_values = reshape(local_getfield_or(search_domain, 'T_grid', []), 1, []);
max_P = local_getfield_or(options, 'max_P', max(P_values));
max_T = local_getfield_or(options, 'max_T', max(T_values));
min_P = max(2, local_getfield_or(options, 'min_P', 2));
min_T = max(2, local_getfield_or(options, 'min_T', 2));

can_expand_right = max(P_values) < max_P || max(T_values) < max_T;
can_expand_left = min(P_values) > min_P || min(T_values) > min_T;

if (~quality.right_plateau_reached || logical(local_getfield_or(quality, 'is_search_domain_unsaturated', false))) && ~can_expand_right
    decision.should_expand = false;
    decision.state = "limit_reached";
    decision.reason = "upper_bound_limit_reached";
    decision.reason_detail = "The right-side saturation target was not reached before hitting the configured upper search-domain limits.";
    decision.limiting_factor = "search_upper_bound";
    return;
end

if ~quality.left_zero_reached && ~can_expand_left
    decision.should_expand = false;
    decision.state = "limit_reached";
    decision.reason = "limit_reached_insufficient_transition";
    decision.reason_detail = "The left-side near-zero floor was not reached before hitting the configured lower search-domain limits.";
    decision.limiting_factor = "search_lower_bound";
    return;
end
end

function reason = local_limit_reason(quality)
if local_getfield_or(quality, 'no_feasible_point_found', false)
    reason = "no_feasible_point_found";
elseif ~local_getfield_or(quality, 'right_plateau_reached', false)
    reason = "boundary_dominated_but_budget_exhausted";
else
    reason = "max_iterations_reached";
end
end

function tf = local_domains_equivalent(a, b)
tf = isequal(reshape(local_getfield_or(a, 'P_values', local_getfield_or(a, 'P_grid', [])), 1, []), ...
             reshape(local_getfield_or(b, 'P_values', local_getfield_or(b, 'P_grid', [])), 1, [])) && ...
     isequal(reshape(local_getfield_or(a, 'T_values', local_getfield_or(a, 'T_grid', [])), 1, []), ...
             reshape(local_getfield_or(b, 'T_values', local_getfield_or(b, 'T_grid', [])), 1, []));
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
