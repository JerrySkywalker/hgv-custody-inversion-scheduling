function [cfg_out, selection, profile] = mb_cli_configure_search_profile(cfg_in, interactive, opts)
%MB_CLI_CONFIGURE_SEARCH_PROFILE CLI helper for MB search-profile configuration.

if nargin < 1 || isempty(cfg_in)
    cfg_out = milestone_common_defaults();
else
    cfg_out = milestone_common_defaults(cfg_in);
end
if nargin < 2 || isempty(interactive)
    interactive = true;
end
if nargin < 3 || isempty(opts)
    opts = struct();
end

selection = local_default_selection(cfg_out);
selection = local_apply_overrides(selection, opts);

if interactive
    selection = local_prompt_selection(cfg_out, selection);
end

[cfg_out, profile] = local_apply_selection(cfg_out, selection);
if interactive
    meta = cfg_out.milestones.MB_semantic_compare;
    fprintf('[run_stages][CLI] search-domain: %s\n', char(string(local_getfield_or(meta, 'search_domain_label', ""))));
    fprintf('[run_stages][CLI] plot-domain: %s\n', char(string(local_getfield_or(meta, 'plot_domain_label', ""))));
    fprintf('[run_stages][CLI] cache: %s\n', char(format_mb_cache_policy_label(local_getfield_or(meta, 'cache_policy', 'all_reuse'), local_getfield_or(meta, 'cache_profile', struct()), "short")));
    fprintf('[run_stages][CLI] incremental: %s\n', char(format_mb_incremental_policy_label(meta, "short")));
    fprintf('[run_stages][CLI] parallel: %s\n', char(format_mb_parallel_policy_label(meta, "short")));
    fprintf('[run_stages][CLI] boundary diagnostics: %s\n', char(format_mb_boundary_diagnostics_label(local_getfield_or(meta, 'boundary_diagnostics_enabled', true), "short")));
end
end

function selection = local_default_selection(cfg)
meta = cfg.milestones.MB_semantic_compare;
profile_name = char(string(local_getfield_or(meta, 'search_profile', 'mb_default')));
profile = get_mb_search_profile(profile_name, cfg);
selection = struct();
selection.run_mode = local_default_run_mode(profile_name, local_getfield_or(meta, 'stage05_replica', struct()));
selection.enable_search_profile_manager = logical(local_getfield_or(meta, 'enable_search_profile_manager', true));
selection.profile_name = profile_name;
selection.profile_mode = char(string(local_getfield_or(meta, 'search_profile_mode', local_getfield_or(profile, 'profile_mode', "expand_default"))));
selection.figure_family = 'passratio';
selection.semantic_mode = char(string(local_getfield_or(meta, 'mode', profile.semantic_mode)));
selection.sensor_groups = resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', cellstr(string(profile.sensor_group_names))));
selection.heights_to_run = reshape(local_getfield_or(meta, 'heights_to_run', profile.height_grid_km), 1, []);
selection.search_range_source = char(string(local_getfield_or(meta, 'search_range_source', 'profile_default')));
selection.search_domain_policy = char(string(local_getfield_or(meta, 'search_domain_policy', 'profile_default')));
selection.plot_domain_policy = char(string(local_getfield_or(meta, 'plot_domain_policy', 'data_range')));
selection.P_grid = reshape(local_getfield_or(meta, 'P_grid', profile.P_grid), 1, []);
selection.T_grid = reshape(local_getfield_or(meta, 'T_grid', profile.T_grid), 1, []);
selection.plot_xlim_ns = reshape(local_getfield_or(meta, 'plot_xlim_ns', profile.Ns_xlim_plot), 1, []);
selection.cache_policy = char(string(local_getfield_or(meta, 'cache_policy', 'all_reuse')));
selection.cache_strict_compatibility = logical(local_getfield_or(local_getfield_or(meta, 'cache_profile', struct()), 'strict_compatibility', true));
selection.auto_tune_requested = logical(local_getfield_or(local_getfield_or(meta, 'auto_tune', struct()), 'enabled', profile.auto_tune.enabled));
selection.auto_tune_mode = char(string(local_getfield_or(local_getfield_or(meta, 'auto_tune', struct()), 'mode', local_default_autotune_mode(meta))));
selection.parallel_policy = char(string(local_getfield_or(meta, 'parallel_policy', 'off')));
selection.incremental_expansion_enabled = logical(local_getfield_or(meta, 'incremental_expansion_enabled', local_getfield_or(meta, 'allow_auto_expand_upper', false)));
selection.boundary_diagnostics_enabled = logical(local_getfield_or(meta, 'boundary_diagnostics_enabled', true));
selection.baseline_validation_only = isequal(selection.sensor_groups, {'baseline'}) && isequal(selection.heights_to_run, 1000) && strcmpi(selection.semantic_mode, 'comparison');
selection.manual_override = struct();
end

function selection = local_prompt_selection(cfg, selection)
fprintf('\n[run_stages][CLI] ===== 配置 MB search profile =====\n');
fprintf('[run_stages][CLI] 直接回车表示保留默认值。\n');

selection.run_mode = local_ask_choice('run mode', selection.run_mode, ...
    {'default', 'dense', 'strict_stage05_replica', 'strict_stage05_validation_only', 'compare_semantics', 'auto_plot_tune'}, ...
    local_run_mode_labels());
selection.profile_name = local_profile_name_from_run_mode(selection.run_mode, selection.profile_name);
selection.enable_search_profile_manager = local_ask_yesno('enable search profile manager', selection.enable_search_profile_manager);
selection.profile_name = local_ask_choice('profile preset', selection.profile_name, ...
    {'mb_default', 'mb_dense_local', 'mb_heavy', 'strict_stage05_replica', 'mb_auto_plot_tune'}, ...
    local_profile_labels(cfg, {'mb_default', 'mb_dense_local', 'mb_heavy', 'strict_stage05_replica', 'mb_auto_plot_tune'}));
selection.profile_mode = local_ask_choice('profile mode', selection.profile_mode, ...
    {'expand_default', 'expand_heavy', 'paper', 'strict_replica'}, ...
    local_profile_mode_labels({'expand_default', 'expand_heavy', 'paper', 'strict_replica'}));
if strcmpi(selection.profile_mode, 'strict_replica')
    selection.profile_name = 'strict_stage05_replica';
end
profile = get_mb_search_profile(selection.profile_name, cfg);
selection.figure_family = local_ask_choice('figure family', selection.figure_family, ...
    {'passratio', 'heatmap', 'comparison', 'control_stage05', 'strict_replica'});

selection.baseline_validation_only = local_ask_yesno('baseline validation only', selection.baseline_validation_only);
selection.semantic_mode = local_ask_choice('semantic mode', selection.semantic_mode, {'legacyDG', 'closedD', 'comparison'});

sensor_default = strjoin(local_default_sensor_groups(selection.baseline_validation_only, profile, selection), ',');
local_print_labeled_list('sensor groups', list_sensor_param_groups(), local_sensor_labels(list_sensor_param_groups()));
sensor_token = local_ask_csv_token('sensor groups', sensor_default, ...
    {'baseline', 'optimistic', 'robust', 'stage05_strict_reference', 'all'});
selection.sensor_groups = local_parse_csv_cell(sensor_token);

height_mode_default = local_default_height_mode(selection.baseline_validation_only);
height_mode = local_ask_choice('height mode', height_mode_default, {'validation', 'default', 'custom'});
switch lower(height_mode)
    case 'validation'
        selection.heights_to_run = 1000;
    case 'custom'
        selection.heights_to_run = local_ask_vector('custom heights_to_run', profile.height_grid_km);
    otherwise
        selection.heights_to_run = reshape(profile.height_grid_km, 1, []);
end

selection.search_range_source = local_ask_choice('search range source', selection.search_range_source, ...
    {'profile_default', 'manual_override', 'auto_tuned_profile'});
selection.search_domain_policy = local_ask_choice('search domain policy', selection.search_domain_policy, ...
    {'profile_default', 'expand_if_unsaturated', 'strict_stage05_reference', 'custom'}, ...
    local_search_domain_policy_labels());
selection.plot_domain_policy = local_ask_choice('plot domain policy', selection.plot_domain_policy, ...
    {'search_profile', 'data_range', 'frontier_summary', 'strict_stage05_reference', 'custom'}, ...
    local_plot_domain_policy_labels());
selection.manual_override = struct();
if strcmpi(selection.search_range_source, 'manual_override')
    selection.P_grid = local_ask_vector('manual P_grid', profile.P_grid);
    selection.T_grid = local_ask_vector('manual T_grid', profile.T_grid);
    selection.plot_xlim_ns = local_ask_vector('manual plot_xlim_ns', profile.Ns_xlim_plot);
    selection.manual_override = struct( ...
        'P_grid', reshape(selection.P_grid, 1, []), ...
        'T_grid', reshape(selection.T_grid, 1, []), ...
        'P_values', reshape(selection.P_grid, 1, []), ...
        'T_values', reshape(selection.T_grid, 1, []), ...
        'plot_xlim_ns', reshape(selection.plot_xlim_ns, 1, []), ...
        'Ns_xlim_plot', reshape(selection.plot_xlim_ns, 1, []));
elseif strcmpi(selection.search_range_source, 'auto_tuned_profile')
    selection.P_grid = reshape(local_get_autotuned_or(profile.P_grid, cfg, 'recommended_P_grid'), 1, []);
    selection.T_grid = reshape(local_get_autotuned_or(profile.T_grid, cfg, 'recommended_T_grid'), 1, []);
    selection.plot_xlim_ns = reshape(local_get_autotuned_or(profile.Ns_xlim_plot, cfg, 'recommended_plot_xlim_ns'), 1, []);
else
    selection.P_grid = reshape(profile.P_grid, 1, []);
    selection.T_grid = reshape(profile.T_grid, 1, []);
    selection.plot_xlim_ns = reshape(profile.Ns_xlim_plot, 1, []);
end
if strcmpi(selection.search_range_source, 'manual_override') && ~strcmpi(selection.search_domain_policy, 'strict_stage05_reference')
    selection.search_domain_policy = 'custom';
end
if ~isempty(selection.plot_xlim_ns) && strcmpi(selection.plot_domain_policy, 'data_range') && strcmpi(selection.search_range_source, 'manual_override')
    selection.plot_domain_policy = 'custom';
end

selection.cache_policy = local_ask_choice('cache policy', selection.cache_policy, ...
    {'all_reuse', 'truth_only', 'no_reuse'});
selection.cache_strict_compatibility = local_ask_yesno('cache strict compatibility check', selection.cache_strict_compatibility);
selection.parallel_policy = local_ask_choice('parallel policy', selection.parallel_policy, ...
    {'off', 'task_bundle', 'task_plus_partition'}, ...
    local_parallel_policy_labels());
selection.incremental_expansion_enabled = local_ask_yesno('enable incremental expansion', selection.incremental_expansion_enabled);
selection.boundary_diagnostics_enabled = local_ask_yesno('enable boundary diagnostics export', selection.boundary_diagnostics_enabled);
selection.auto_tune_mode = local_ask_choice('auto tune mode', selection.auto_tune_mode, ...
    {'off', 'evaluate_only', 'iterative_recommend_only', 'iterative_recommend_and_apply'});
selection.auto_tune_requested = ~strcmpi(selection.auto_tune_mode, 'off');
if selection.auto_tune_requested
    current_max_iter = local_getfield_or(local_getfield_or(cfg.milestones.MB_semantic_compare, 'auto_tune', struct()), 'max_iterations', profile.auto_tune.max_iterations);
    current_max_P = local_getfield_or(local_getfield_or(cfg.milestones.MB_semantic_compare, 'auto_tune', struct()), 'max_P', profile.auto_tune.max_P);
    current_max_T = local_getfield_or(local_getfield_or(cfg.milestones.MB_semantic_compare, 'auto_tune', struct()), 'max_T', profile.auto_tune.max_T);
    selection.auto_tune_max_iterations = local_ask_scalar('auto tune max iterations', current_max_iter);
    selection.auto_tune_max_P = local_ask_scalar('auto tune max P', current_max_P);
    selection.auto_tune_max_T = local_ask_scalar('auto tune max T', current_max_T);
else
    selection.auto_tune_max_iterations = [];
    selection.auto_tune_max_P = [];
    selection.auto_tune_max_T = [];
end

fprintf('[run_stages][CLI] ===== MB search profile 配置完成 =====\n\n');
end

function [cfg_out, profile] = local_apply_selection(cfg_in, selection)
context = struct();
if logical(selection.enable_search_profile_manager)
    context = struct( ...
        'user_selected_profile_name', string(selection.profile_name), ...
        'profile_mode', string(selection.profile_mode), ...
        'figure_family', string(selection.figure_family), ...
        'semantic_mode', string(selection.semantic_mode), ...
        'sensor_group', string(local_pick_first(selection.sensor_groups, 'baseline')), ...
        'height_km', local_pick_first(selection.heights_to_run, 1000), ...
        'search_domain_policy', string(selection.search_domain_policy), ...
        'plot_domain_policy', string(selection.plot_domain_policy), ...
        'search_range_source', string(selection.search_range_source), ...
        'cli_manual_override', selection.manual_override);
    context.search_domain_policy = string(selection.search_domain_policy);
    context.plot_domain_policy = string(selection.plot_domain_policy);
    context.search_domain_override = struct( ...
        'allow_auto_expand_upper', logical(selection.incremental_expansion_enabled));
    context.plot_domain_override = struct( ...
        'plot_xlim_mode', string(selection.plot_domain_policy));
    if strcmpi(selection.plot_domain_policy, 'custom') && numel(selection.plot_xlim_ns) == 2
        context.plot_domain_override.plot_xlim_ns = reshape(selection.plot_xlim_ns, 1, []);
    end
    if strcmpi(selection.search_range_source, 'auto_tuned_profile')
        context.autotuned_profile_if_any = local_extract_autotuned_profile_override(cfg_in);
    end
    profile = resolve_mb_search_profile_for_context(context, cfg_in);
else
    profile = local_build_current_profile(cfg_in, selection);
end
if logical(local_getfield_or(local_getfield_or(profile, 'stage05_replica', struct()), 'strict', false))
    selection.semantic_mode = char(string(profile.semantic_mode));
    selection.sensor_groups = cellstr(string(profile.sensor_group_names));
    selection.heights_to_run = reshape(profile.height_grid_km, 1, []);
    selection.P_grid = reshape(profile.P_values, 1, []);
    selection.T_grid = reshape(profile.T_values, 1, []);
    selection.plot_xlim_ns = reshape(profile.Ns_xlim_plot, 1, []);
    selection.manual_override = struct();
    selection.auto_tune_requested = false;
    selection.search_domain_policy = 'strict_stage05_reference';
    selection.plot_domain_policy = 'strict_stage05_reference';
    selection.incremental_expansion_enabled = false;
    selection.cache_strict_compatibility = true;
else
    profile = merge_mb_search_profile_overrides(profile, struct( ...
        'semantic_mode', string(selection.semantic_mode), ...
        'sensor_group_names', {cellstr(string(selection.sensor_groups))}, ...
        'height_grid_km', reshape(selection.heights_to_run, 1, []), ...
        'P_grid', reshape(selection.P_grid, 1, []), ...
        'T_grid', reshape(selection.T_grid, 1, []), ...
        'P_values', reshape(selection.P_grid, 1, []), ...
        'T_values', reshape(selection.T_grid, 1, []), ...
        'plot_xlim_ns', reshape(selection.plot_xlim_ns, 1, []), ...
        'Ns_xlim_plot', reshape(selection.plot_xlim_ns, 1, []), ...
        'auto_tune', local_build_cli_autotune_override(selection)), "cli_selection");
end
profile = local_apply_cache_policy(profile, selection.cache_policy);

[cfg_out, profile] = apply_mb_search_profile_to_cfg(cfg_in, profile);
cfg_out.milestones.MB_semantic_compare.cli_selection = selection;
cfg_out.milestones.MB_semantic_compare.enable_search_profile_manager = logical(selection.enable_search_profile_manager);
cfg_out.milestones.MB_semantic_compare.search_range_source = string(selection.search_range_source);
cfg_out.milestones.MB_semantic_compare.search_domain_policy = string(selection.search_domain_policy);
cfg_out.milestones.MB_semantic_compare.plot_domain_policy = string(selection.plot_domain_policy);
cfg_out.milestones.MB_semantic_compare.cache_policy = string(selection.cache_policy);
cfg_out.milestones.MB_semantic_compare.search_profile_mode = string(selection.profile_mode);
cfg_out.milestones.MB_semantic_compare.parallel_policy = string(selection.parallel_policy);
cfg_out.milestones.MB_semantic_compare.incremental_expansion_enabled = logical(selection.incremental_expansion_enabled);
cfg_out.milestones.MB_semantic_compare.boundary_diagnostics_enabled = logical(selection.boundary_diagnostics_enabled);
cfg_out.milestones.MB_semantic_compare.cache_profile.strict_compatibility = logical(selection.cache_strict_compatibility);
cfg_out.milestones.MB_semantic_compare.search_profile_context = context;
cfg_out.milestones.MB_semantic_compare.stage05_replica.validation_only = strcmpi(selection.run_mode, 'strict_stage05_validation_only');
if cfg_out.milestones.MB_semantic_compare.stage05_replica.validation_only
    cfg_out.milestones.MB_semantic_compare.mode = 'legacyDG';
    cfg_out.milestones.MB_semantic_compare.sensor_groups = {'stage05_strict_reference'};
    cfg_out.milestones.MB_semantic_compare.heights_to_run = 1000;
    cfg_out.milestones.MB_semantic_compare.run_dense_local = false;
    cfg_out.milestones.MB_semantic_compare.auto_tune.enabled = false;
end
cfg_out.milestones.MB_semantic_compare.auto_tune.mode = string(selection.auto_tune_mode);
cfg_out.milestones.MB_semantic_compare.auto_tune_apply = strcmpi(selection.auto_tune_mode, 'iterative_recommend_and_apply');
end

function profile = local_apply_cache_policy(profile, cache_policy)
switch lower(cache_policy)
    case 'all_reuse'
        profile.cache.enable = true;
        profile.cache.reuse_truth = true;
        profile.cache.reuse_semantic_eval = true;
    case 'truth_only'
        profile.cache.enable = true;
        profile.cache.reuse_truth = true;
        profile.cache.reuse_semantic_eval = false;
    case 'no_reuse'
        profile.cache.enable = false;
        profile.cache.reuse_truth = false;
        profile.cache.reuse_semantic_eval = false;
    otherwise
        error('Unknown MB cache policy: %s', cache_policy);
end
end

function selection = local_apply_overrides(selection, opts)
names = fieldnames(opts);
for idx = 1:numel(names)
    selection.(names{idx}) = opts.(names{idx});
end
if ischar(selection.sensor_groups) || (isstring(selection.sensor_groups) && isscalar(selection.sensor_groups))
    selection.sensor_groups = local_parse_csv_cell(selection.sensor_groups);
end
selection.heights_to_run = reshape(selection.heights_to_run, 1, []);
selection.P_grid = reshape(selection.P_grid, 1, []);
selection.T_grid = reshape(selection.T_grid, 1, []);
selection.plot_xlim_ns = reshape(local_getfield_or(selection, 'plot_xlim_ns', []), 1, []);
selection.manual_override = local_getfield_or(selection, 'manual_override', struct());
selection.auto_tune_mode = char(string(local_getfield_or(selection, 'auto_tune_mode', 'off')));
selection.enable_search_profile_manager = logical(local_getfield_or(selection, 'enable_search_profile_manager', true));
if local_is_missing_field(opts, 'auto_tune_requested') && local_is_missing_field(selection, 'auto_tune_requested')
    profile_name = local_profile_name_from_run_mode(selection.run_mode, selection.profile_name);
    profile = get_mb_search_profile(profile_name);
    selection.auto_tune_requested = logical(profile.auto_tune.enabled) || strcmpi(selection.search_range_source, 'auto_tuned_profile');
end
end

function run_mode = local_default_run_mode(profile_name, stage05_replica_cfg)
if nargin >= 2 && isstruct(stage05_replica_cfg) && logical(local_getfield_or(stage05_replica_cfg, 'validation_only', false))
    run_mode = 'strict_stage05_validation_only';
    return;
end
switch lower(char(string(profile_name)))
    case 'mb_dense_local'
        run_mode = 'dense';
    case {'strict_stage05_replica', 'mb_stage05_strict_replica'}
        run_mode = 'strict_stage05_replica';
    case 'mb_auto_plot_tune'
        run_mode = 'auto_plot_tune';
    otherwise
        run_mode = 'default';
end
end

function profile_name = local_profile_name_from_run_mode(run_mode, fallback_name)
switch lower(char(string(run_mode)))
    case 'default'
        profile_name = 'mb_default';
    case 'dense'
        profile_name = 'mb_dense_local';
    case 'strict_stage05_replica'
        profile_name = 'strict_stage05_replica';
    case 'strict_stage05_validation_only'
        profile_name = 'strict_stage05_replica';
    case 'compare_semantics'
        profile_name = 'mb_default';
    case 'auto_plot_tune'
        profile_name = 'mb_auto_plot_tune';
    otherwise
        profile_name = fallback_name;
end
end

function groups = local_default_sensor_groups(baseline_validation_only, profile, selection)
if baseline_validation_only
    groups = {'baseline'};
elseif strcmpi(char(string(selection.run_mode)), 'strict_stage05_replica')
    groups = {'stage05_strict_reference'};
elseif strcmpi(char(string(selection.run_mode)), 'strict_stage05_validation_only')
    groups = {'stage05_strict_reference'};
else
    groups = cellstr(string(profile.sensor_group_names));
end
end

function mode = local_default_height_mode(baseline_validation_only)
if baseline_validation_only
    mode = 'validation';
else
    mode = 'default';
end
end

function token = local_ask_csv_token(name, default_val, allowed_values)
s = input(sprintf('%s [%s] options=%s: ', name, default_val, strjoin(allowed_values, '/')), 's');
if isempty(strtrim(s))
    token = default_val;
    return;
end
parts = local_parse_csv_cell(s);
if any(strcmpi(parts, 'all'))
    token = 'all';
    return;
end
for idx = 1:numel(parts)
    if ~any(strcmpi(parts{idx}, allowed_values))
        warning('%s 输入非法，保留默认值。', name);
        token = default_val;
        return;
    end
end
token = strjoin(parts, ',');
end

function value = local_ask_choice(name, default_val, choices, labels)
if nargin < 4 || isempty(labels)
    labels = choices;
end
local_print_labeled_list(name, choices, labels);
s = input(sprintf('%s [%s]: ', name, default_val), 's');
if isempty(strtrim(s))
    value = default_val;
    return;
end
trimmed = strtrim(s);
numeric_hit = str2double(trimmed);
if isfinite(numeric_hit) && numeric_hit >= 1 && numeric_hit <= numel(choices) && abs(numeric_hit - round(numeric_hit)) < eps
    value = choices{round(numeric_hit)};
    return;
end
hit = find(strcmpi(trimmed, choices), 1);
if isempty(hit)
    warning('%s 输入非法，保留默认值。', name);
    value = default_val;
else
    value = choices{hit};
end
end

function value = local_ask_yesno(name, default_val)
if default_val
    default_token = 'y';
else
    default_token = 'n';
end
s = input(sprintf('%s [y/n, default=%s]: ', name, default_token), 's');
if isempty(strtrim(s))
    value = logical(default_val);
    return;
end
s = lower(strtrim(s));
if any(strcmp(s, {'y', 'yes', '1'}))
    value = true;
elseif any(strcmp(s, {'n', 'no', '0'}))
    value = false;
else
    warning('%s 输入非法，保留默认值。', name);
    value = logical(default_val);
end
end

function values = local_ask_vector(name, default_val)
s = input(sprintf('%s %s: ', name, mat2str(default_val)), 's');
if isempty(strtrim(s))
    values = default_val;
    return;
end
tmp = str2num(s); %#ok<ST2NM>
if isempty(tmp)
    warning('%s 输入非法，保留默认值。', name);
    values = default_val;
else
    values = reshape(tmp, 1, []);
end
end

function value = local_ask_scalar(name, default_val)
s = input(sprintf('%s [%g]: ', name, default_val), 's');
if isempty(strtrim(s))
    value = default_val;
    return;
end
tmp = str2double(s);
if ~isfinite(tmp)
    warning('%s 输入非法，保留默认值。', name);
    value = default_val;
else
    value = tmp;
end
end

function parts = local_parse_csv_cell(token)
raw = split(string(token), ',');
raw = strtrim(raw);
raw = raw(raw ~= "");
if isempty(raw)
    parts = {'baseline'};
else
    parts = cellstr(raw(:).');
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function tf = local_is_missing_field(S, field_name)
tf = true;
if ~(isstruct(S) && isfield(S, field_name))
    return;
end
value = S.(field_name);
if ischar(value) || isstring(value) || iscell(value) || isnumeric(value) || islogical(value)
    tf = numel(value) == 0;
else
    tf = false;
end
end

function values = local_get_autotuned_or(fallback, cfg, field_name)
values = fallback;
meta = cfg.milestones.MB_semantic_compare;
if ~isfield(meta, 'auto_tune_result') || ~isstruct(meta.auto_tune_result)
    return;
end
if isfield(meta.auto_tune_result, field_name)
    values = meta.auto_tune_result.(field_name);
end
end

function override = local_extract_autotuned_profile_override(cfg)
override = struct();
meta = cfg.milestones.MB_semantic_compare;
if ~isfield(meta, 'auto_tune_result') || ~isstruct(meta.auto_tune_result)
    return;
end
tune_result = meta.auto_tune_result;
if isfield(tune_result, 'recommended_P_grid')
    override.P_grid = reshape(tune_result.recommended_P_grid, 1, []);
    override.P_values = override.P_grid;
end
if isfield(tune_result, 'recommended_T_grid')
    override.T_grid = reshape(tune_result.recommended_T_grid, 1, []);
    override.T_values = override.T_grid;
end
if isfield(tune_result, 'recommended_plot_xlim_ns')
    override.plot_xlim_ns = reshape(tune_result.recommended_plot_xlim_ns, 1, []);
    override.Ns_xlim_plot = override.plot_xlim_ns;
end
end

function profile = local_build_current_profile(cfg_in, selection)
meta = cfg_in.milestones.MB_semantic_compare;
profile = get_mb_search_profile(local_getfield_or(meta, 'search_profile', 'mb_default'), cfg_in);
profile = merge_mb_search_profile_overrides(profile, resolve_mb_search_profile_mode(local_getfield_or(selection, 'profile_mode', 'expand_default'), cfg_in), "cli_profile_mode");
profile.semantic_mode = string(selection.semantic_mode);
profile.sensor_group_names = cellstr(string(selection.sensor_groups));
profile.height_grid_km = reshape(selection.heights_to_run, 1, []);
profile.P_grid = reshape(selection.P_grid, 1, []);
profile.T_grid = reshape(selection.T_grid, 1, []);
profile.P_values = reshape(selection.P_grid, 1, []);
profile.T_values = reshape(selection.T_grid, 1, []);
profile.plot_xlim_ns = reshape(selection.plot_xlim_ns, 1, []);
profile.Ns_xlim_plot = reshape(selection.plot_xlim_ns, 1, []);
profile.auto_tune = local_build_cli_autotune_override(selection, profile);
end

function auto_tune_override = local_build_cli_autotune_override(selection, profile)
if nargin < 2 || isempty(profile)
    profile = struct();
end
base = local_getfield_or(profile, 'auto_tune', struct());
auto_tune_override = base;
auto_tune_override.enabled = logical(selection.auto_tune_requested);
auto_tune_override.mode = string(selection.auto_tune_mode);
if isfield(selection, 'auto_tune_max_iterations') && ~isempty(selection.auto_tune_max_iterations)
    auto_tune_override.max_iterations = selection.auto_tune_max_iterations;
end
if isfield(selection, 'auto_tune_max_P') && ~isempty(selection.auto_tune_max_P)
    auto_tune_override.max_P = selection.auto_tune_max_P;
end
if isfield(selection, 'auto_tune_max_T') && ~isempty(selection.auto_tune_max_T)
    auto_tune_override.max_T = selection.auto_tune_max_T;
end
end

function mode = local_default_autotune_mode(meta)
mode = "off";
auto_tune_cfg = local_getfield_or(meta, 'auto_tune', struct());
if isfield(auto_tune_cfg, 'mode') && strlength(string(auto_tune_cfg.mode)) > 0
    mode = string(auto_tune_cfg.mode);
elseif logical(local_getfield_or(auto_tune_cfg, 'enabled', false))
    if logical(local_getfield_or(meta, 'auto_tune_apply', false))
        mode = "iterative_recommend_and_apply";
    else
        mode = "iterative_recommend_only";
    end
end
mode = char(mode);
end

function value = local_pick_first(values, fallback)
if isempty(values)
    value = fallback;
elseif iscell(values)
    value = values{1};
else
    value = values(1);
end
end

function labels = local_profile_labels(cfg, choices)
labels = cell(size(choices));
for idx = 1:numel(choices)
    labels{idx} = char(format_mb_search_profile_label(choices{idx}, cfg, "short"));
end
end

function labels = local_profile_mode_labels(choices)
labels = cell(size(choices));
for idx = 1:numel(choices)
    labels{idx} = char(format_mb_search_profile_mode_label(choices{idx}, "short"));
end
end

function labels = local_sensor_labels(choices)
labels = cell(size(choices));
for idx = 1:numel(choices)
    labels{idx} = char(format_mb_sensor_group_label(choices{idx}, "short"));
end
end

function labels = local_search_domain_policy_labels()
labels = { ...
    'profile_default (use the selected profile search grid)', ...
    'expand_if_unsaturated (allow incremental search-domain growth)', ...
    'strict_stage05_reference (locked Stage05 reference search domain)', ...
    'custom (use the current manual or patched search domain)'};
end

function labels = local_plot_domain_policy_labels()
labels = { ...
    'search_profile (plot directly over the current search domain)', ...
    'data_range (data-adaptive plotting window)', ...
    'frontier_summary (summary-style window anchored to search domain)', ...
    'strict_stage05_reference (locked Stage05 envelope window)', ...
    'custom (use the current manual plot x limits)'};
end

function labels = local_parallel_policy_labels()
choices = {'off', 'task_bundle', 'task_plus_partition'};
labels = cell(size(choices));
for idx = 1:numel(choices)
    labels{idx} = char(format_mb_parallel_policy_label(struct('parallel_policy', choices{idx}), "short"));
end
end

function labels = local_run_mode_labels()
labels = { ...
    'default (routine MB semantic compare)', ...
    'dense (local dense refinement focus)', ...
    'strict_stage05_replica (locked Stage05 semantics + strict reference)', ...
    'strict_stage05_validation_only (strict replica validation export only)', ...
    'compare_semantics (legacyDG vs closedD comparison)', ...
    'auto_plot_tune (autotune-first passratio exploration)'};
end

function local_print_labeled_list(name, choices, labels)
fprintf('[run_stages][CLI] %s options:\n', name);
for idx = 1:numel(choices)
    if idx <= numel(labels) && ~isempty(labels{idx})
        fprintf('  %d) %s\n', idx, labels{idx});
    else
        fprintf('  %d) %s\n', idx, choices{idx});
    end
end
end
