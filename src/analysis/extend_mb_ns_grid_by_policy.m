function [next_domain, action] = extend_mb_ns_grid_by_policy(search_domain, target_block, diagnostics, options)
%EXTEND_MB_NS_GRID_BY_POLICY Expand the effective Ns support domain by updating P/T coverage.

if nargin < 2 || isempty(target_block)
    target_block = struct();
end
if nargin < 3 || isempty(diagnostics)
    diagnostics = struct();
end
if nargin < 4 || isempty(options)
    options = struct();
end

next_domain = search_domain;
action = struct('name', "hold", 'reason', "Search-domain coverage already matches the current Ns target block.");

P_values = reshape(local_getfield_or(search_domain, 'P_grid', local_getfield_or(search_domain, 'P_values', [])), 1, []);
T_values = reshape(local_getfield_or(search_domain, 'T_grid', local_getfield_or(search_domain, 'T_values', [])), 1, []);
if isempty(P_values) || isempty(T_values)
    return;
end

target_ns_max = local_getfield_or(target_block, 'ns_max', local_getfield_or(search_domain, 'ns_search_max', NaN));
target_ns_min = local_getfield_or(target_block, 'ns_min', local_getfield_or(search_domain, 'ns_search_min', NaN));
target_ns_step = local_getfield_or(target_block, 'ns_step', local_getfield_or(search_domain, 'ns_search_step', NaN));
current_ns_max = local_getfield_or(search_domain, 'ns_search_max', NaN);

expand_step_T = max(1, local_getfield_or(search_domain, 'expand_step_T', local_getfield_or(options, 'expand_step_T', local_getfield_or(target_block, 'ns_step', 4))));
required_T_max = ceil(target_ns_max ./ max(P_values));
required_T_max = expand_step_T * ceil(required_T_max / expand_step_T);
current_T_max = max(T_values);

if required_T_max > current_T_max
    added_T = (current_T_max + expand_step_T):expand_step_T:required_T_max;
    T_values = unique([T_values, added_T], 'stable');
end

next_domain.P_grid = reshape(P_values, 1, []);
next_domain.T_grid = reshape(T_values, 1, []);
next_domain.P_values = reshape(P_values, 1, []);
next_domain.T_values = reshape(T_values, 1, []);
next_domain.ns_search_min = target_ns_min;
next_domain.ns_search_max = target_ns_max;
next_domain.ns_search_step = target_ns_step;
next_domain.expand_step_ns = target_ns_step;
next_domain.current_expand_block = string(local_getfield_or(target_block, 'name', local_getfield_or(search_domain, 'current_expand_block', "expanded_block")));

search_unsaturated = logical(local_getfield_or(diagnostics, 'search_domain_unsaturated', false)) || ...
    ~logical(local_getfield_or(diagnostics, 'right_unity_reached', false));
if target_ns_max > current_ns_max
    action.name = "expand_Ns_block";
    if search_unsaturated
        action.reason = "Extend the effective Ns ceiling and Walker slot-count coverage toward the missing right-side plateau.";
    else
        action.reason = "Extend the effective Ns coverage to resolve boundary-dominated heatmap or frontier points.";
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
