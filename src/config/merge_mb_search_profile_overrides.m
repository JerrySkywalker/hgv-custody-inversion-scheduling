function profile = merge_mb_search_profile_overrides(base_profile, override, source_tag)
%MERGE_MB_SEARCH_PROFILE_OVERRIDES Merge MB search-profile overrides and normalize aliases.

if nargin < 1 || isempty(base_profile)
    base_profile = mb_search_profile_defaults();
end
if nargin < 2 || isempty(override)
    override = struct();
end
if nargin < 3
    source_tag = "";
end

profile = milestone_common_merge_structs(base_profile, override);
profile = local_normalize_profile(profile);
profile = local_record_source(profile, source_tag);
end

function profile = local_normalize_profile(profile)
if ~isfield(profile, 'P_grid') || isempty(profile.P_grid)
    profile.P_grid = reshape(local_getfield_or(profile, 'P_values', []), 1, []);
end
if ~isfield(profile, 'T_grid') || isempty(profile.T_grid)
    profile.T_grid = reshape(local_getfield_or(profile, 'T_values', []), 1, []);
end
profile.P_grid = reshape(profile.P_grid, 1, []);
profile.T_grid = reshape(profile.T_grid, 1, []);
profile.P_values = reshape(profile.P_grid, 1, []);
profile.T_values = reshape(profile.T_grid, 1, []);

if ~isfield(profile, 'plot_xlim_ns') || isempty(profile.plot_xlim_ns)
    profile.plot_xlim_ns = reshape(local_getfield_or(profile, 'Ns_xlim_plot', []), 1, []);
end
if ~isfield(profile, 'Ns_xlim_plot') || isempty(profile.Ns_xlim_plot)
    profile.Ns_xlim_plot = reshape(local_getfield_or(profile, 'plot_xlim_ns', []), 1, []);
end

if ~isfield(profile, 'Ns_target_window') || isempty(profile.Ns_target_window)
    profile.Ns_target_window = reshape(profile.Ns_xlim_plot, 1, []);
end
profile.height_grid_km = reshape(local_getfield_or(profile, 'height_grid_km', []), 1, []);
profile.inclination_grid_deg = reshape(local_getfield_or(profile, 'inclination_grid_deg', []), 1, []);
profile.Ns_initial_range = reshape(local_getfield_or(profile, 'Ns_initial_range', []), 1, []);
profile.Ns_expand_blocks = local_normalize_expand_blocks(local_getfield_or(profile, 'Ns_expand_blocks', []));
profile.Ns_hard_max = local_getfield_or(profile, 'Ns_hard_max', NaN);
profile.Ns_allow_expand = logical(local_getfield_or(profile, 'Ns_allow_expand', false));
profile.solve_domain_mode = string(local_getfield_or(profile, 'solve_domain_mode', "fixed"));
profile.expand_strategy = string(local_getfield_or(profile, 'expand_strategy', "incremental_blocks"));
profile.expand_trigger_policy = local_normalize_policy(local_getfield_or(profile, 'expand_trigger_policy', struct()), struct( ...
    'require_right_unity', true, ...
    'required_upper_target', 0.99, ...
    'end_slope_tol', 0.01, ...
    'boundary_hit_ratio_threshold', 0.25, ...
    'allow_summary_warning_trigger', true));
profile.expand_stop_policy = local_normalize_policy(local_getfield_or(profile, 'expand_stop_policy', struct()), struct( ...
    'max_rounds_without_improvement', 2, ...
    'min_passratio_gain', 0.01, ...
    'min_frontier_gain', 1, ...
    'time_budget_s', 1800, ...
    'stop_if_two_rounds_without_new_feasible', true));
profile.profile_mode = string(local_getfield_or(profile, 'profile_mode', "expand_default"));
profile.profile_mode_description = string(local_getfield_or(profile, 'profile_mode_description', "incremental Ns expansion up to 400 with a balanced runtime budget"));

if ~isfield(profile, 'search_domain') || ~isstruct(profile.search_domain)
    profile.search_domain = struct();
end
if ~isfield(profile, 'plot_domain') || ~isstruct(profile.plot_domain)
    profile.plot_domain = struct();
end
profile.search_domain = local_normalize_search_domain(profile.search_domain, profile);
profile.plot_domain = local_normalize_plot_domain(profile.plot_domain, profile);

if ~isfield(profile, 'auto_tune') || ~isstruct(profile.auto_tune)
    profile.auto_tune = struct();
end
profile.auto_tune.enabled = logical(local_getfield_or(profile.auto_tune, 'enabled', false));
profile.auto_tune.max_iterations = local_getfield_or(profile.auto_tune, 'max_iterations', 5);
profile.auto_tune.max_candidate_count = local_getfield_or(profile.auto_tune, 'max_candidate_count', 12);
profile.auto_tune.expand_step_P = local_getfield_or(profile.auto_tune, 'expand_step_P', 2);
profile.auto_tune.expand_step_T = local_getfield_or(profile.auto_tune, 'expand_step_T', 4);
profile.auto_tune.max_P = local_getfield_or(profile.auto_tune, 'max_P', 16);
profile.auto_tune.max_T = local_getfield_or(profile.auto_tune, 'max_T', 24);
profile.auto_tune.require_left_zero = logical(local_getfield_or(profile.auto_tune, 'require_left_zero', true));
profile.auto_tune.require_right_one = logical(local_getfield_or(profile.auto_tune, 'require_right_one', true));
profile.auto_tune.require_mid_transition = logical(local_getfield_or(profile.auto_tune, 'require_mid_transition', true));
profile.auto_tune.right_plateau_tol = local_getfield_or(profile.auto_tune, 'right_plateau_tol', 0.95);
profile.auto_tune.left_floor_tol = local_getfield_or(profile.auto_tune, 'left_floor_tol', 0.05);

profile.autotune_enable = profile.auto_tune.enabled;
profile.autotune_max_iterations = profile.auto_tune.max_iterations;
profile.autotune_max_P = profile.auto_tune.max_P;
profile.autotune_max_T = profile.auto_tune.max_T;
profile.autotune_expand_step_P = profile.auto_tune.expand_step_P;
profile.autotune_expand_step_T = profile.auto_tune.expand_step_T;
profile.autotune_require_left_zero = profile.auto_tune.require_left_zero;
profile.autotune_require_right_one = profile.auto_tune.require_right_one;
profile.autotune_require_mid_transition = profile.auto_tune.require_mid_transition;
profile.autotune_right_plateau_tol = profile.auto_tune.right_plateau_tol;
profile.autotune_left_floor_tol = profile.auto_tune.left_floor_tol;

if ~isfield(profile, 'metadata') || ~isstruct(profile.metadata)
    profile.metadata = struct();
end
profile.metadata.profile_mode = string(profile.profile_mode);
profile.metadata.profile_mode_description = string(profile.profile_mode_description);
profile.metadata.override_sources = cellstr(string(local_getfield_or(profile.metadata, 'override_sources', {})));
profile.metadata.context = local_getfield_or(profile.metadata, 'context', struct());
end

function search_domain = local_normalize_search_domain(search_domain, profile)
search_domain.policy_name = string(local_getfield_or(search_domain, 'policy_name', "profile_default"));
search_domain.height_grid_km = reshape(local_getfield_or(search_domain, 'height_grid_km', local_getfield_or(profile, 'height_grid_km', [])), 1, []);
search_domain.inclination_grid_deg = reshape(local_getfield_or(search_domain, 'inclination_grid_deg', local_getfield_or(profile, 'inclination_grid_deg', [])), 1, []);
search_domain.P_grid = reshape(local_getfield_or(search_domain, 'P_grid', local_getfield_or(profile, 'P_values', local_getfield_or(profile, 'P_grid', []))), 1, []);
search_domain.T_grid = reshape(local_getfield_or(search_domain, 'T_grid', local_getfield_or(profile, 'T_values', local_getfield_or(profile, 'T_grid', []))), 1, []);
search_domain.Ns_initial_range = reshape(local_getfield_or(search_domain, 'Ns_initial_range', local_getfield_or(profile, 'Ns_initial_range', [])), 1, []);
search_domain.Ns_expand_blocks = local_normalize_expand_blocks(local_getfield_or(search_domain, 'Ns_expand_blocks', local_getfield_or(profile, 'Ns_expand_blocks', [])));
search_domain.Ns_hard_max = local_getfield_or(search_domain, 'Ns_hard_max', local_getfield_or(profile, 'Ns_hard_max', NaN));
search_domain.Ns_allow_expand = logical(local_getfield_or(search_domain, 'Ns_allow_expand', local_getfield_or(profile, 'Ns_allow_expand', false)));
search_domain.solve_domain_mode = string(local_getfield_or(search_domain, 'solve_domain_mode', local_getfield_or(profile, 'solve_domain_mode', "fixed")));
search_domain.expand_strategy = string(local_getfield_or(search_domain, 'expand_strategy', local_getfield_or(profile, 'expand_strategy', "incremental_blocks")));
search_domain.expand_trigger_policy = local_normalize_policy(local_getfield_or(search_domain, 'expand_trigger_policy', local_getfield_or(profile, 'expand_trigger_policy', struct())), local_getfield_or(profile, 'expand_trigger_policy', struct()));
search_domain.expand_stop_policy = local_normalize_policy(local_getfield_or(search_domain, 'expand_stop_policy', local_getfield_or(profile, 'expand_stop_policy', struct())), local_getfield_or(profile, 'expand_stop_policy', struct()));
search_domain.allow_auto_expand_upper = logical(local_getfield_or(search_domain, 'allow_auto_expand_upper', search_domain.Ns_allow_expand));
search_domain.allow_lower_bound_expansion = logical(local_getfield_or(search_domain, 'allow_lower_bound_expansion', false));
search_domain.max_expand_iterations = local_getfield_or(search_domain, 'max_expand_iterations', numel(search_domain.Ns_expand_blocks));
end

function plot_domain = local_normalize_plot_domain(plot_domain, profile)
plot_domain.plot_xlim_mode = string(local_getfield_or(plot_domain, 'plot_xlim_mode', "data_range"));
plot_domain.plot_xlim_ns = reshape(local_getfield_or(plot_domain, 'plot_xlim_ns', local_getfield_or(profile, 'Ns_xlim_plot', local_getfield_or(profile, 'plot_xlim_ns', []))), 1, []);
plot_domain.plot_ylim_passratio = reshape(local_getfield_or(plot_domain, 'plot_ylim_passratio', local_getfield_or(profile, 'plot_ylim_passratio', [0, 1.05])), 1, []);
plot_domain.plot_ylim_dg = reshape(local_getfield_or(plot_domain, 'plot_ylim_dg', local_getfield_or(profile, 'plot_ylim_dg', [])), 1, []);
plot_domain.plot_domain_guardrail_mode = string(local_getfield_or(plot_domain, 'plot_domain_guardrail_mode', "standard"));
plot_domain.show_domain_annotation = logical(local_getfield_or(plot_domain, 'show_domain_annotation', true));
end

function profile = local_record_source(profile, source_tag)
token = strtrim(char(string(source_tag)));
if isempty(token)
    return;
end

sources = cellstr(string(local_getfield_or(profile.metadata, 'override_sources', {})));
if isempty(sources)
    sources = {'default'};
end
if ~ismember(token, sources)
    sources{end + 1} = token;
end
profile.metadata.override_sources = sources;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function blocks = local_normalize_expand_blocks(blocks_in)
if isempty(blocks_in)
    blocks = repmat(struct('name', "", 'ns_min', NaN, 'ns_step', NaN, 'ns_max', NaN, 'ns_values', []), 1, 0);
    return;
end
if ~isstruct(blocks_in)
    error('MB Ns_expand_blocks must be provided as a struct array.');
end
blocks = blocks_in;
for idx = 1:numel(blocks)
    blocks(idx).name = string(local_getfield_or(blocks(idx), 'name', "block" + idx));
    blocks(idx).ns_min = local_getfield_or(blocks(idx), 'ns_min', NaN);
    blocks(idx).ns_step = local_getfield_or(blocks(idx), 'ns_step', NaN);
    blocks(idx).ns_max = local_getfield_or(blocks(idx), 'ns_max', NaN);
    ns_values = local_getfield_or(blocks(idx), 'ns_values', []);
    if isempty(ns_values) && all(isfinite([blocks(idx).ns_min, blocks(idx).ns_step, blocks(idx).ns_max]))
        ns_values = blocks(idx).ns_min:blocks(idx).ns_step:blocks(idx).ns_max;
    end
    blocks(idx).ns_values = reshape(ns_values, 1, []);
end
end

function policy = local_normalize_policy(policy_in, defaults)
if nargin < 1 || ~isstruct(policy_in)
    policy_in = struct();
end
if nargin < 2 || ~isstruct(defaults)
    defaults = struct();
end
policy = milestone_common_merge_structs(defaults, policy_in);
end
