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
sensor_group = char(string(local_getfield_or(options, 'sensor_group', profile.sensor_group_names{1})));

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
out.summary = struct( ...
    'mode', "stage05_strict_replica", ...
    'search_profile', string(profile.name), ...
    'sensor_group', string(legacy_output.sensor_group.name), ...
    'family_set', {family_set}, ...
    'heights_to_run', heights_to_run, ...
    'interpretation_note', "Strict Stage05 replica keeps Stage05 search-domain defaults, Stage05 sensor defaults, and Stage05 D_G-based semantics within the MB wrapper shell.");
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
