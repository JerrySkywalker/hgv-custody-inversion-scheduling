function decision = should_expand_mb_search_domain(search_domain, diagnostics, history, options)
%SHOULD_EXPAND_MB_SEARCH_DOMAIN Decide whether the MB search domain should expand.

if nargin < 4 || isempty(options)
    options = struct();
end

decision = struct( ...
    'should_expand', false, ...
    'state', "limit_reached", ...
    'reason', "limit_reached_without_right_plateau", ...
    'reason_detail', "Search-domain diagnostics indicate that more Ns coverage is still desirable, but the next expansion was not approved.", ...
    'limiting_factor', "", ...
    'stagnated', false);

Ns_allow_expand = logical(local_getfield_or(search_domain, 'Ns_allow_expand', false)) && ...
    logical(local_getfield_or(search_domain, 'allow_auto_expand_upper', false));
max_iterations = local_getfield_or(options, 'max_iterations', max(1, local_getfield_or(search_domain, 'max_expand_iterations', 0) + 1));
iteration_idx = numel(history) + 1;
elapsed_s = local_getfield_or(options, 'elapsed_s', NaN);
time_budget_s = local_getfield_or(options, 'time_budget_s', inf);
hard_max = local_getfield_or(options, 'hard_max', local_getfield_or(search_domain, 'Ns_hard_max', NaN));
max_rounds_without_improvement = local_getfield_or(local_getfield_or(search_domain, 'expand_stop_policy', struct()), ...
    'max_rounds_without_improvement', 2);
last_improvement_iteration = local_getfield_or(options, 'last_improvement_iteration', 0);

right_unity_reached = logical(local_getfield_or(diagnostics, 'right_unity_reached', false));
frontier_truncated = logical(local_getfield_or(diagnostics, 'frontier_truncated', false));
boundary_dominated = logical(local_getfield_or(diagnostics, 'boundary_dominated', false));
search_unsaturated = logical(local_getfield_or(diagnostics, 'search_domain_unsaturated', false));
no_feasible_point_found = logical(local_getfield_or(diagnostics, 'no_feasible_point_found', false));
added_design_count = local_getfield_or(diagnostics, 'added_design_count', 0);
current_ns_max = local_getfield_or(search_domain, 'ns_search_max', NaN);
hit_hard_max = isfinite(hard_max) && isfinite(current_ns_max) && current_ns_max >= hard_max - 1.0e-9;

if ~Ns_allow_expand
    decision.state = "fixed_domain";
    if right_unity_reached && ~frontier_truncated && ~boundary_dominated && ~search_unsaturated
        decision.reason = "unity_plateau_reached";
        decision.reason_detail = "The fixed search domain already resolves the right-side plateau and the frontier is internally defined.";
    elseif no_feasible_point_found
        decision.reason = "no_feasible_point_found";
        decision.reason_detail = "No feasible point was found inside the fixed search domain.";
    else
        decision.reason = "fixed_domain_no_expand";
        decision.reason_detail = "The active profile locks the search domain, so no incremental Ns expansion is allowed.";
    end
    return;
end

if right_unity_reached && ~frontier_truncated && ~boundary_dominated && ~search_unsaturated
    decision.state = "success";
    decision.reason = "unity_plateau_reached";
    decision.reason_detail = "The right-side unity plateau is resolved and the frontier no longer depends on the current search upper bound.";
    return;
end

if no_feasible_point_found && hit_hard_max
    decision.state = "limit_reached";
    decision.reason = "no_feasible_point_found";
    decision.reason_detail = "No feasible point was found before reaching the configured hard search upper bound.";
    decision.limiting_factor = "hard_upper_bound";
    return;
end

if isfinite(time_budget_s) && isfinite(elapsed_s) && elapsed_s >= time_budget_s
    decision.state = "limit_reached";
    decision.reason = "time_budget_exceeded";
    decision.reason_detail = "The iterative search-domain expansion exhausted the configured wall-clock budget.";
    decision.limiting_factor = "time_budget";
    return;
end

if iteration_idx >= max_iterations
    decision.state = "limit_reached";
    decision.reason = local_limit_reason(diagnostics, hit_hard_max);
    decision.reason_detail = "Reached the maximum number of incremental search-domain iterations.";
    decision.limiting_factor = "max_iterations";
    return;
end

if hit_hard_max
    decision.state = "limit_reached";
    decision.reason = local_limit_reason(diagnostics, true);
    decision.reason_detail = "The configured hard Ns upper bound was reached before the diagnostics met the saturation target.";
    decision.limiting_factor = "hard_upper_bound";
    return;
end

if iteration_idx >= 3 && (iteration_idx - last_improvement_iteration) > max_rounds_without_improvement
    decision.state = "stalled";
    decision.reason = "two_rounds_no_improvement";
    decision.reason_detail = "Two consecutive expansions failed to improve pass-ratio saturation, frontier coverage, or internal heatmap support.";
    decision.stagnated = true;
    return;
end

if iteration_idx >= 2 && added_design_count == 0 && no_feasible_point_found
    decision.state = "stalled";
    decision.reason = "no_new_feasible_design_in_added_block";
    decision.reason_detail = "The newest Ns expansion block contributed no feasible design and the search remains empty.";
    decision.stagnated = true;
    return;
end

decision.should_expand = true;
decision.state = "continue";
decision.reason = "continue_search";
decision.reason_detail = "The current search domain remains unsaturated or boundary dominated, so the next Ns block should be evaluated.";
if search_unsaturated || ~right_unity_reached
    decision.limiting_factor = "right_plateau";
elseif frontier_truncated || boundary_dominated
    decision.limiting_factor = "boundary_hit";
else
    decision.limiting_factor = "improvement_search";
end
end

function reason = local_limit_reason(diagnostics, hit_hard_max)
if local_getfield_or(diagnostics, 'no_feasible_point_found', false)
    reason = "no_feasible_point_found";
elseif hit_hard_max
    reason = "hard_upper_bound_reached";
elseif ~local_getfield_or(diagnostics, 'right_unity_reached', false)
    reason = "limit_reached_without_right_plateau";
else
    reason = "limit_reached_insufficient_transition";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
