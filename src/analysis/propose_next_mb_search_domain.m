function [next_domain, action] = propose_next_mb_search_domain(search_domain, quality, options)
%PROPOSE_NEXT_MB_SEARCH_DOMAIN Propose the next search-domain expansion step.

if nargin < 3 || isempty(options)
    options = struct();
end

next_domain = search_domain;
action = struct('name', "hold", 'reason', "Search domain already satisfies the current update rule.");

P_values = reshape(local_getfield_or(search_domain, 'P_grid', local_getfield_or(search_domain, 'P_values', [])), 1, []);
T_values = reshape(local_getfield_or(search_domain, 'T_grid', local_getfield_or(search_domain, 'T_values', [])), 1, []);
max_P = local_getfield_or(options, 'max_P', max(P_values));
max_T = local_getfield_or(options, 'max_T', max(T_values));
step_P = local_getfield_or(options, 'expand_step_P', 2);
step_T = local_getfield_or(options, 'expand_step_T', 4);
min_P = max(2, local_getfield_or(options, 'min_P', 2));
min_T = max(2, local_getfield_or(options, 'min_T', 2));

if (~quality.right_plateau_reached || logical(local_getfield_or(quality, 'is_search_domain_unsaturated', false))) && max(T_values) < max_T
    T_values = unique([T_values, min(max_T, T_values(end) + step_T)], 'stable');
    action.name = "expand_T_upper";
    action.reason = "Extend the Walker slot-count upper bound to search for the missing right-end plateau.";
elseif (~quality.right_plateau_reached || logical(local_getfield_or(quality, 'is_search_domain_unsaturated', false))) && max(P_values) < max_P
    P_values = unique([P_values, min(max_P, P_values(end) + step_P)], 'stable');
    action.name = "expand_P_upper";
    action.reason = "Extend the Walker plane-count upper bound to search for the missing right-end plateau.";
elseif ~quality.left_zero_reached && min(T_values) > min_T
    T_values = unique([max(min_T, T_values(1) - step_T), T_values], 'stable');
    action.name = "expand_T_lower";
    action.reason = "Lower the Walker slot-count bound to expose the near-zero left floor.";
elseif ~quality.left_zero_reached && min(P_values) > min_P
    P_values = unique([max(min_P, P_values(1) - step_P), P_values], 'stable');
    action.name = "expand_P_lower";
    action.reason = "Lower the Walker plane-count bound to expose the near-zero left floor.";
end

next_domain.P_grid = reshape(P_values, 1, []);
next_domain.T_grid = reshape(T_values, 1, []);
next_domain.P_values = reshape(P_values, 1, []);
next_domain.T_values = reshape(T_values, 1, []);
next_domain.ns_search_min = min(P_values) * min(T_values);
next_domain.ns_search_max = max(P_values) * max(T_values);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
