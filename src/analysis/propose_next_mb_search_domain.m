function [next_domain, action] = propose_next_mb_search_domain(search_domain, quality, options)
%PROPOSE_NEXT_MB_SEARCH_DOMAIN Propose the next search-domain expansion step.

if nargin < 3 || isempty(options)
    options = struct();
end

next_domain = search_domain;
action = struct('name', "hold", 'reason', "Search domain already satisfies the current update rule.");

P_values = reshape(local_getfield_or(search_domain, 'P_grid', local_getfield_or(search_domain, 'P_values', [])), 1, []);
T_values = reshape(local_getfield_or(search_domain, 'T_grid', local_getfield_or(search_domain, 'T_values', [])), 1, []);
plan = build_mb_ns_search_plan(search_domain, struct('Ns_hard_max', local_getfield_or(options, 'hard_max', NaN)));
expand_blocks = local_getfield_or(plan, 'blocks', repmat(struct('name', "", 'ns_min', NaN, 'ns_step', NaN, 'ns_max', NaN, 'ns_values', []), 1, 0));
hard_max = local_getfield_or(options, 'hard_max', local_getfield_or(plan, 'hard_max', local_getfield_or(search_domain, 'Ns_hard_max', NaN)));
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
        target_ns_min = current_ns_max + target_ns_step;
    else
        return;
    end
else
    target_ns_max = min(local_getfield_or(target_block, 'ns_max', current_ns_max), hard_max);
    target_ns_step = local_getfield_or(target_block, 'ns_step', local_getfield_or(search_domain, 'ns_search_step', 4));
    block_name = string(local_getfield_or(target_block, 'name', "next_block"));
    target_ns_min = local_getfield_or(target_block, 'ns_min', local_getfield_or(search_domain, 'ns_search_min', NaN));
end

if ~isfinite(target_ns_max) || target_ns_max <= current_ns_max + 1.0e-9
    return;
end

target_block = struct( ...
    'name', block_name, ...
    'ns_min', target_ns_min, ...
    'ns_step', target_ns_step, ...
    'ns_max', target_ns_max);
[next_domain, action] = extend_mb_ns_grid_by_policy(search_domain, target_block, quality, struct( ...
    'expand_step_T', local_getfield_or(search_domain, 'expand_step_T', local_getfield_or(options, 'expand_step_T', 4))));
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
