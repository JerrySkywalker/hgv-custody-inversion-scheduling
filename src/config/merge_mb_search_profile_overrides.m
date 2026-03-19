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
profile.profile_mode = string(local_getfield_or(profile, 'profile_mode', "debug"));
profile.profile_mode_description = string(local_getfield_or(profile, 'profile_mode_description', "fast validation with smaller budget"));

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
    sources{end + 1} = token; %#ok<AGROW>
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
