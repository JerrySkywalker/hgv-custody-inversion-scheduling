function plan = build_mb_ns_search_plan(search_domain, options)
%BUILD_MB_NS_SEARCH_PLAN Build a normalized, versionable Ns expansion plan for MB search.

if nargin < 1 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 2 || isempty(options)
    options = struct();
end

initial_range = reshape(local_getfield_or(search_domain, 'Ns_initial_range', [NaN, NaN, NaN]), 1, []);
if numel(initial_range) < 3
    initial_range = [NaN, NaN, NaN];
end

blocks = local_getfield_or(search_domain, 'Ns_expand_blocks', repmat(struct( ...
    'name', "", 'ns_min', NaN, 'ns_step', NaN, 'ns_max', NaN, 'ns_values', []), 1, 0));
hard_max = local_getfield_or(search_domain, 'Ns_hard_max', local_getfield_or(options, 'Ns_hard_max', NaN));
allow_expand = logical(local_getfield_or(search_domain, 'Ns_allow_expand', false));

plan = struct();
plan.policy_name = string(local_getfield_or(search_domain, 'policy_name', "profile_default"));
plan.strategy = string(local_getfield_or(search_domain, 'expand_strategy', "incremental_blocks"));
plan.solve_domain_mode = string(local_getfield_or(search_domain, 'solve_domain_mode', "fixed"));
plan.allow_expand = allow_expand;
plan.hard_max = hard_max;
plan.initial = local_make_block("initial", initial_range(1), initial_range(2), initial_range(3));
plan.blocks = local_normalize_blocks(blocks, hard_max);
plan.block_count = numel(plan.blocks);
plan.current_ns_min = local_getfield_or(search_domain, 'ns_search_min', plan.initial.ns_min);
plan.current_ns_max = local_getfield_or(search_domain, 'ns_search_max', plan.initial.ns_max);
plan.current_ns_step = local_getfield_or(search_domain, 'ns_search_step', plan.initial.ns_step);
plan.current_block_name = string(local_getfield_or(search_domain, 'current_expand_block', plan.initial.name));
plan.plan_digest = string(jsonencode(struct( ...
    'initial', plan.initial, ...
    'blocks', plan.blocks, ...
    'hard_max', plan.hard_max, ...
    'allow_expand', plan.allow_expand, ...
    'strategy', plan.strategy)));
end

function blocks = local_normalize_blocks(blocks_in, hard_max)
blocks = repmat(struct('name', "", 'ns_min', NaN, 'ns_step', NaN, 'ns_max', NaN, 'ns_values', []), 1, numel(blocks_in));
for idx = 1:numel(blocks_in)
    src = blocks_in(idx);
    blocks(idx) = local_make_block( ...
        local_getfield_or(src, 'name', "block_" + idx), ...
        local_getfield_or(src, 'ns_min', NaN), ...
        local_getfield_or(src, 'ns_step', NaN), ...
        min(local_getfield_or(src, 'ns_max', NaN), hard_max));
end
end

function block = local_make_block(name, ns_min, ns_step, ns_max)
if ~isfinite(ns_min) || ~isfinite(ns_step) || ~isfinite(ns_max) || ns_step <= 0 || ns_max < ns_min
    ns_values = [];
else
    ns_values = ns_min:ns_step:ns_max;
end
block = struct( ...
    'name', string(name), ...
    'ns_min', ns_min, ...
    'ns_step', ns_step, ...
    'ns_max', ns_max, ...
    'ns_values', reshape(ns_values, 1, []));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
