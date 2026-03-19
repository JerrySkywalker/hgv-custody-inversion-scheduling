function out = run_mb_stage05_strict_replica(cfg, options)
%RUN_MB_STAGE05_STRICT_REPLICA Run strict Stage05 replica semantics under the MB shell.

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(options)
    options = struct();
end

profile = build_stage05_strict_replica_profile(cfg);
reference_defaults = load_stage05_reference_defaults(cfg);
family_set = local_resolve_family_set(local_getfield_or(options, 'family_set', {'nominal'}));
heights_to_run = reshape(local_getfield_or(options, 'heights_to_run', profile.height_grid_km), 1, []);
sensor_group = local_first_sensor_group(profile);
lock_manifest = local_build_lock_manifest(options, profile);

fprintf('[MB][strict replica] locked profile: %s\n', char(format_mb_search_profile_label(profile, cfg, "detailed")));
fprintf('[MB][strict replica] locked sensor: %s\n', char(format_mb_sensor_group_label(sensor_group, "detailed")));

[cfg_profile, profile] = apply_mb_search_profile_to_cfg(cfg, profile);
legacy_output = run_mb_legacydg_semantics(cfg_profile, struct( ...
    'sensor_group', sensor_group, ...
    'heights_to_run', heights_to_run, ...
    'family_set', {family_set}, ...
    'i_grid_deg', reshape(profile.inclination_grid_deg, 1, []), ...
    'P_grid', reshape(profile.P_grid, 1, []), ...
    'T_grid', reshape(profile.T_grid, 1, []), ...
    'F_fixed', local_getfield_or(options, 'F_fixed', reference_defaults.F_fixed), ...
    'use_parallel', logical(local_getfield_or(options, 'use_parallel', reference_defaults.use_parallel))));

out = struct();
out.mode = "stage05_strict_replica";
out.reference_defaults = reference_defaults;
out.strict_profile = profile;
out.legacy_output = legacy_output;
out.sensor_group = legacy_output.sensor_group;
out.runs = legacy_output.runs;
out.lock_manifest = lock_manifest;
out.summary = struct( ...
    'mode', "stage05_strict_replica", ...
    'semantic_mode', "legacyDG", ...
    'search_profile', string(profile.name), ...
    'sensor_group', string(legacy_output.sensor_group.name), ...
    'plot_style', "stage05_replica_style", ...
    'lock_manifest', lock_manifest, ...
    'family_set', {family_set}, ...
    'heights_to_run', heights_to_run, ...
    'interpretation_note', "Strict Stage05 replica keeps Stage05 search-domain defaults, Stage05 sensor defaults, and Stage05 D_G-based semantics within the MB wrapper shell.");

if logical(local_getfield_or(options, 'build_validation_summary', false))
    [out.validation_summary, out.validation_meta] = build_stage05_strict_replica_validation_summary(out, cfg, options);
    [out.validation_manifest_struct, out.validation_manifest_table] = build_stage05_strict_replica_manifest(out, out.validation_meta);
else
    out.validation_summary = table();
    out.validation_meta = struct();
    out.validation_manifest_struct = struct();
    out.validation_manifest_table = table();
end
end

function family_set = local_resolve_family_set(family_input)
tokens = cellstr(string(family_input));
tokens = cellfun(@(s) lower(strtrim(s)), tokens, 'UniformOutput', false);
if any(strcmp(tokens, 'all'))
    family_set = {'nominal', 'heading', 'critical'};
else
    family_set = unique(tokens, 'stable');
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function manifest = local_build_lock_manifest(options, profile)
manifest = struct();
manifest.semantic_mode = "legacyDG";
manifest.sensor_group = string(local_first_sensor_group(profile));
manifest.search_profile = string(profile.name);
manifest.plot_style = "stage05_replica_style";
manifest.ignored_option_fields = strings(0, 1);

ignored = strings(0, 1);
if isstruct(options)
    if isfield(options, 'sensor_group') && ~strcmpi(char(string(options.sensor_group)), local_first_sensor_group(profile))
        ignored(end + 1, 1) = "sensor_group"; %#ok<AGROW>
    end
    if isfield(options, 'semantic_mode') && ~strcmpi(char(string(options.semantic_mode)), 'legacyDG')
        ignored(end + 1, 1) = "semantic_mode"; %#ok<AGROW>
    end
    if isfield(options, 'search_profile') && ~strcmpi(char(string(options.search_profile)), char(string(profile.name)))
        ignored(end + 1, 1) = "search_profile"; %#ok<AGROW>
    end
end
manifest.ignored_option_fields = ignored;
end

function sensor_group = local_first_sensor_group(profile)
groups = cellstr(string(local_getfield_or(profile, 'sensor_group_names', {'stage05_strict_reference'})));
sensor_group = char(string(groups{1}));
end
