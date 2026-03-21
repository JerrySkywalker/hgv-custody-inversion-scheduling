function [next_domain, action] = propose_next_mb_search_domain(search_domain, quality, options)
%PROPOSE_NEXT_MB_SEARCH_DOMAIN Propose the next search-domain expansion step.

if nargin < 3 || isempty(options)
    options = struct();
end

next_domain = search_domain;
action = struct('name', "hold", 'reason', "Search domain already satisfies the current update rule.");

P_values = reshape(local_getfield_or(search_domain, 'P_grid', local_getfield_or(search_domain, 'P_values', [])), 1, []);
T_values = reshape(local_getfield_or(search_domain, 'T_grid', local_getfield_or(search_domain, 'T_values', [])), 1, []);
expand_blocks = local_getfield_or(search_domain, 'Ns_expand_blocks', repmat(struct('name', "", 'ns_min', NaN, 'ns_step', NaN, 'ns_max', NaN, 'ns_values', []), 1, 0));
hard_max = local_getfield_or(options, 'hard_max', local_getfield_or(search_domain, 'Ns_hard_max', NaN));
current_ns_max = local_getfield_or(search_domain, 'ns_search_max', NaN);

if isempty(P_values) || isempty(T_values)
    return;
end

search_unsaturated = logical(local_getfield_or(quality, 'search_domain_unsaturated', false)) || ...
    ~logical(local_getfield_or(quality, 'right_unity_reached', false));

target_block = local_pick_next_block(expand_blocks, current_ns_max);
if isempty(target_block)
    if isfinite(hard_max) && isfinite(current_ns_max) && current_ns_max < hard_max
        target_ns_max = hard_max;
        target_ns_step = local_getfield_or(search_domain, 'ns_search_step', local_getfield_or(search_domain, 'expand_step_ns', 4));
        block_name = "hard_max_extension";
    else
        return;
    end
else
    target_ns_max = min(local_getfield_or(target_block, 'ns_max', current_ns_max), hard_max);
    target_ns_step = local_getfield_or(target_block, 'ns_step', local_getfield_or(search_domain, 'ns_search_step', 4));
    block_name = string(local_getfield_or(target_block, 'name', "next_block"));
end

if ~isfinite(target_ns_max) || target_ns_max <= current_ns_max + 1.0e-9
    return;
end

expand_step_T = max(1, local_getfield_or(search_domain, 'expand_step_T', local_getfield_or(options, 'expand_step_T', 4)));
required_T_max = ceil(target_ns_max ./ max(P_values));
required_T_max = expand_step_T * ceil(required_T_max / expand_step_T);
current_T_max = max(T_values);
if required_T_max > current_T_max
    added_T = (current_T_max + expand_step_T):expand_step_T:required_T_max;
    T_values = unique([T_values, added_T], 'stable');
    action.name = "expand_Ns_block";
    if search_unsaturated
        action.reason = "Append the next configured Ns expansion block by extending the Walker slot-count grid toward the missing right-side plateau.";
    else
        action.reason = "Append the next configured Ns expansion block to relieve boundary-dominated frontier or heatmap diagnostics.";
    end
else
    action.name = "advance_Ns_ceiling";
    action.reason = "Advance the search-domain Ns ceiling to the next configured block while keeping the current Walker grids.";
end

next_domain.P_grid = reshape(P_values, 1, []);
next_domain.T_grid = reshape(T_values, 1, []);
next_domain.P_values = reshape(P_values, 1, []);
next_domain.T_values = reshape(T_values, 1, []);
next_domain.ns_search_min = min(P_values) * min(T_values);
next_domain.ns_search_max = target_ns_max;
next_domain.ns_search_step = local_getfield_or(search_domain, 'ns_search_step', target_ns_step);
next_domain.expand_step_ns = target_ns_step;
next_domain.current_expand_block = block_name;
end

function block = local_pick_next_block(expand_blocks, current_ns_max)
block = struct([]);
for idx = 1:numel(expand_blocks)
    candidate = expand_blocks(idx);
    if local_getfield_or(candidate, 'ns_max', NaN) > current_ns_max + 1.0e-9
        block = candidate;
        return;
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
