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
end

function selection = local_default_selection(cfg)
meta = cfg.milestones.MB_semantic_compare;
profile_name = char(string(local_getfield_or(meta, 'search_profile', 'mb_default')));
profile = get_mb_search_profile(profile_name, cfg);
selection = struct();
selection.run_mode = local_default_run_mode(profile_name);
selection.profile_name = profile_name;
selection.semantic_mode = char(string(profile.semantic_mode));
selection.sensor_groups = cellstr(string(profile.sensor_group_names));
selection.heights_to_run = reshape(profile.height_grid_km, 1, []);
selection.search_range_source = 'profile_default';
selection.P_grid = reshape(profile.P_grid, 1, []);
selection.T_grid = reshape(profile.T_grid, 1, []);
selection.cache_policy = 'all_reuse';
selection.auto_tune_requested = logical(profile.auto_tune.enabled);
selection.baseline_validation_only = isequal(selection.sensor_groups, {'baseline'}) && isequal(selection.heights_to_run, 1000);
end

function selection = local_prompt_selection(cfg, selection)
fprintf('\n[run_stages][CLI] ===== 配置 MB search profile =====\n');
fprintf('[run_stages][CLI] 直接回车表示保留默认值。\n');

selection.run_mode = local_ask_choice('run mode', selection.run_mode, ...
    {'default', 'dense', 'strict_stage05_replica', 'compare_semantics', 'auto_plot_tune'});
selection.profile_name = local_profile_name_from_run_mode(selection.run_mode, selection.profile_name);
profile = get_mb_search_profile(selection.profile_name, cfg);

selection.baseline_validation_only = local_ask_yesno('baseline validation only', selection.baseline_validation_only);
selection.semantic_mode = local_ask_choice('semantic mode', selection.semantic_mode, {'legacyDG', 'closedD', 'comparison'});

sensor_default = strjoin(local_default_sensor_groups(selection.baseline_validation_only, profile, selection), ',');
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
    {'profile_default', 'manual', 'auto_tune'});
if strcmpi(selection.search_range_source, 'manual')
    selection.P_grid = local_ask_vector('manual P_grid', profile.P_grid);
    selection.T_grid = local_ask_vector('manual T_grid', profile.T_grid);
else
    selection.P_grid = reshape(profile.P_grid, 1, []);
    selection.T_grid = reshape(profile.T_grid, 1, []);
end

selection.cache_policy = local_ask_choice('cache policy', selection.cache_policy, ...
    {'all_reuse', 'truth_only', 'no_reuse'});
selection.auto_tune_requested = strcmpi(selection.search_range_source, 'auto_tune') || ...
    local_ask_yesno('enable auto tune', selection.auto_tune_requested);

fprintf('[run_stages][CLI] ===== MB search profile 配置完成 =====\n\n');
end

function [cfg_out, profile] = local_apply_selection(cfg_in, selection)
profile_overrides = struct();
profile_overrides.semantic_mode = string(selection.semantic_mode);
profile_overrides.sensor_group_names = {cellstr(string(selection.sensor_groups))};
profile_overrides.height_grid_km = reshape(selection.heights_to_run, 1, []);
profile_overrides.P_grid = reshape(selection.P_grid, 1, []);
profile_overrides.T_grid = reshape(selection.T_grid, 1, []);
profile_overrides.auto_tune = struct('enabled', logical(selection.auto_tune_requested));
profile = get_mb_search_profile(selection.profile_name, cfg_in);
profile = milestone_common_merge_structs(profile, profile_overrides);
profile = local_apply_cache_policy(profile, selection.cache_policy);

[cfg_out, profile] = apply_mb_search_profile_to_cfg(cfg_in, profile);
cfg_out.milestones.MB_semantic_compare.cli_selection = selection;
cfg_out.milestones.MB_semantic_compare.search_range_source = string(selection.search_range_source);
cfg_out.milestones.MB_semantic_compare.cache_policy = string(selection.cache_policy);
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
if ~isfield(opts, 'auto_tune_requested') || isempty(opts.auto_tune_requested)
    profile_name = local_profile_name_from_run_mode(selection.run_mode, selection.profile_name);
    profile = get_mb_search_profile(profile_name);
    selection.auto_tune_requested = logical(profile.auto_tune.enabled) || strcmpi(selection.search_range_source, 'auto_tune');
end
end

function run_mode = local_default_run_mode(profile_name)
switch lower(char(string(profile_name)))
    case 'mb_dense_local'
        run_mode = 'dense';
    case 'mb_stage05_strict_replica'
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
        profile_name = 'mb_stage05_strict_replica';
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

function value = local_ask_choice(name, default_val, choices)
s = input(sprintf('%s [%s] options=%s: ', name, default_val, strjoin(choices, '/')), 's');
if isempty(strtrim(s))
    value = default_val;
    return;
end
hit = find(strcmpi(strtrim(s), choices), 1);
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
