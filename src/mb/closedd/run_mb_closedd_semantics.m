function out = run_mb_closedd_semantics(cfg, options)
%RUN_MB_CLOSEDD_SEMANTICS Run MB closedD semantics through Stage09-compatible wrappers.

mb_safe_startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(options)
    options = struct();
end

closed_cfg = local_normalize_options(cfg, options);
[cfg_sensor, sensor_group] = apply_sensor_param_group_to_cfg(cfg, closed_cfg.sensor_group);
paths = mb_output_paths(cfg_sensor, cfg_sensor.milestones.MB_semantic_compare.milestone_id, cfg_sensor.milestones.MB_semantic_compare.title);
cache_root = fullfile(paths.cache, 'semantic', 'closedD');
ensure_dir(cache_root);

run_bank = repmat(local_empty_run(), 0, 1);
cache_records = repmat(struct('cache_file', "", 'manifest_csv', "", 'cache_hit', false, 'reason', "", 'family_name', "", 'h_km', NaN), 0, 1);
cache_hits = 0;
fresh_evaluations = 0;
for idx_family = 1:numel(closed_cfg.family_set)
    family_name = closed_cfg.family_set{idx_family};
    for idx_h = 1:numel(closed_cfg.heights_to_run)
        h_km = closed_cfg.heights_to_run(idx_h);
        design_table = build_mb_fixed_h_design_table( ...
            h_km, closed_cfg.i_grid_deg, closed_cfg.P_grid, closed_cfg.T_grid, closed_cfg.F_fixed, "closedD_wrapper");
        [run, cache_record] = local_run_or_load_cache(cfg_sensor, closed_cfg, sensor_group, family_name, h_km, design_table, cache_root);
        cache_records(end + 1, 1) = cache_record; %#ok<AGROW>
        cache_hits = cache_hits + double(cache_record.cache_hit);
        fresh_evaluations = fresh_evaluations + double(~cache_record.cache_hit);
        run_bank(end + 1, 1) = run; %#ok<AGROW>
    end
end

out = struct();
out.mode = "closedD";
out.sensor_group = sensor_group;
out.options = closed_cfg;
out.runs = run_bank;
out.cache_records = cache_records;
out.summary = struct( ...
    'mode', "closedD", ...
    'sensor_group', sensor_group.name, ...
    'sensor_label', sensor_group.sensor_label, ...
    'max_off_boresight_deg', sensor_group.max_off_boresight_deg, ...
    'sigma_angle_arcsec', sensor_group.angle_resolution_arcsec, ...
    'sigma_angle_rad', sensor_group.angle_resolution_rad, ...
    'family_set', {closed_cfg.family_set}, ...
    'heights_to_run', closed_cfg.heights_to_run, ...
    'total_run_count', numel(run_bank), ...
    'cache_hits', cache_hits, ...
    'fresh_evaluations', fresh_evaluations, ...
    'interpretation_note', "closedD keeps the Stage09-compatible joint / D-series closure semantics inside the MB comparison shell.");
end

function closed_cfg = local_normalize_options(cfg, options)
meta = cfg.milestones.MB;
closed_cfg = struct();
closed_cfg.sensor_group = char(string(local_getfield_or(options, 'sensor_group', 'baseline')));
closed_cfg.heights_to_run = reshape(local_getfield_or(options, 'heights_to_run', 1000), 1, []);
closed_cfg.i_grid_deg = reshape(local_getfield_or(options, 'i_grid_deg', meta.fixed_h_exploration_i_deg), 1, []);
closed_cfg.P_grid = reshape(local_getfield_or(options, 'P_grid', meta.fixed_h_exploration_P), 1, []);
closed_cfg.T_grid = reshape(local_getfield_or(options, 'T_grid', meta.fixed_h_exploration_T), 1, []);
closed_cfg.F_fixed = local_getfield_or(options, 'F_fixed', 1);
closed_cfg.family_set = local_resolve_family_set(local_getfield_or(options, 'family_set', {'nominal'}));
closed_cfg.use_parallel = logical(local_getfield_or(options, 'use_parallel', true));
closed_cfg.parallel_policy = resolve_mb_parallel_policy(local_getfield_or(options, 'parallel_policy', struct('parallel_policy', 'off')));
closed_cfg.heading_subset_max = local_getfield_or(options, 'heading_subset_max', cfg.milestones.MB.slice_settings.heading_subset_max);
closed_cfg.cache_profile = local_getfield_or(options, 'cache_profile', cfg.milestones.MB_semantic_compare.cache_profile);
closed_cfg.cache_namespace = string(local_getfield_or(options, 'cache_namespace', "mb_closedD"));
end

function [run, cache_record] = local_run_or_load_cache(cfg_sensor, closed_cfg, sensor_group, family_name, h_km, design_table, cache_root)
input_spec = struct( ...
    'semantic_mode', "closedD", ...
    'family_name', string(family_name), ...
    'sensor_group', string(sensor_group.name), ...
    'sensor_params', struct( ...
        'max_off_boresight_deg', sensor_group.max_off_boresight_deg, ...
        'sigma_angle_arcsec', sensor_group.angle_resolution_arcsec, ...
        'sigma_angle_rad', sensor_group.angle_resolution_rad), ...
    'search_domain', struct( ...
        'height_km', h_km, ...
        'inclination_grid_deg', reshape(closed_cfg.i_grid_deg, 1, []), ...
        'P_grid', reshape(closed_cfg.P_grid, 1, []), ...
        'T_grid', reshape(closed_cfg.T_grid, 1, []), ...
        'F_fixed', closed_cfg.F_fixed), ...
    'heading_subset_max', closed_cfg.heading_subset_max);
manifest = build_mb_cache_manifest("semantic_eval", mfilename, input_spec, struct( ...
    'cache_namespace', closed_cfg.cache_namespace, ...
    'semantic_mode', "closedD", ...
    'sensor_group_name', sensor_group.name, ...
    'sensor_params', input_spec.sensor_params, ...
    'search_domain', input_spec.search_domain, ...
    'profile_mode', local_getfield_or(cfg_sensor.milestones.MB_semantic_compare, 'search_profile_mode', ""), ...
    'height_km', h_km, ...
    'family_name', family_name, ...
    'cache_tag', local_getfield_or(closed_cfg.cache_profile, 'tag', "mb_default"), ...
    'compatible_with_plot_only_changes', true, ...
    'compatible_with_export_only_changes', true));
cache_file = fullfile(cache_root, sprintf('mb_closedd_%s_h%d_%s_%s.mat', ...
    char(string(family_name)), round(h_km), char(string(sensor_group.name)), char(manifest.input_hash)));
reuse_semantic_cache = logical(local_getfield_or(closed_cfg.cache_profile, 'reuse_semantic_eval', true));
loaded = struct('hit', false, 'reason', "cache_disabled", 'payload', struct(), 'manifest_csv', "");
if reuse_semantic_cache
    loaded = load_mb_cache_if_compatible(cache_file, manifest);
end

if loaded.hit
    run = loaded.payload.run;
    if ~isfield(run, 'incremental_search_history')
        run.incremental_search_history = table();
    end
    if ~isfield(run, 'incremental_seed_info')
        run.incremental_seed_info = struct();
    end
    cache_record = struct( ...
        'cache_file', string(cache_file), ...
        'manifest_csv', string(loaded.manifest_csv), ...
        'cache_hit', true, ...
        'reason', string(loaded.reason), ...
        'family_name', string(family_name), ...
        'h_km', h_km);
    run.cache_info = cache_record;
    return;
end

[seed_hit, seed_run, seed_cache_record] = local_find_incremental_seed(cache_root, manifest, input_spec, design_table);
if seed_hit
    incremental = evaluate_design_pool_incremental_over_ns(seed_run, design_table, ...
        @(added_designs) evaluate_design_pool_with_stage09_semantics(cfg_sensor, added_designs, family_name, struct( ...
            'sensor_group', sensor_group.name, ...
            'parallel_policy', closed_cfg.parallel_policy, ...
            'use_parallel', closed_cfg.use_parallel, ...
            'heading_subset_max', closed_cfg.heading_subset_max)), ...
        @(merged_eval) aggregate_stage09_semantics_results(merged_eval, h_km, family_name, sensor_group.name, closed_cfg.i_grid_deg), ...
        struct('iteration', 1, 'semantic_mode', "closedD", 'sensor_group', sensor_group.name, ...
            'family_name', family_name, 'height_km', h_km, 'action', "incremental_expand", 'stop_reason', "incremental_merge_completed"));

    run = local_empty_run();
    run.h_km = h_km;
    run.family_name = string(family_name);
    run.design_table = incremental.design_table;
    run.eval_table = incremental.eval_table;
    run.feasible_table = incremental.feasible_table;
    run.aggregate = incremental.aggregate;
    run.summary = local_build_summary(run.eval_table, run.feasible_table, sensor_group, family_name);
    run.incremental_search_history = build_mb_incremental_search_history(incremental.history_row);
    cache_record = struct( ...
        'cache_file', string(cache_file), ...
        'manifest_csv', "", ...
        'cache_hit', false, ...
        'reason', "incremental_seed_merge", ...
        'family_name', string(family_name), ...
        'h_km', h_km);
    artifacts = save_mb_cache_with_manifest(cache_file, struct('run', run), manifest);
    cache_record.manifest_csv = artifacts.manifest_csv;
    run.cache_info = cache_record;
    run.incremental_seed_info = seed_cache_record;
    return;
end

eval_out = evaluate_design_pool_with_stage09_semantics(cfg_sensor, design_table, family_name, struct( ...
    'sensor_group', sensor_group.name, ...
    'parallel_policy', closed_cfg.parallel_policy, ...
    'use_parallel', closed_cfg.use_parallel, ...
    'heading_subset_max', closed_cfg.heading_subset_max));
agg_out = aggregate_stage09_semantics_results(eval_out.eval_table, h_km, family_name, sensor_group.name, closed_cfg.i_grid_deg);

run = local_empty_run();
run.h_km = h_km;
run.family_name = string(family_name);
run.design_table = design_table;
run.eval_table = eval_out.eval_table;
run.feasible_table = eval_out.feasible_table;
run.aggregate = agg_out;
run.summary = eval_out.summary;
run.incremental_search_history = build_mb_incremental_search_history(struct( ...
    'iteration', 1, 'semantic_mode', "closedD", 'sensor_group', sensor_group.name, 'family_name', family_name, ...
    'height_km', h_km, 'action', "fresh_evaluation", 'stop_reason', "initial_domain", 'cache_seed_hit', false, ...
    'previous_design_count', 0, 'added_design_count', height(design_table), 'merged_design_count', height(design_table), ...
    'P_grid', reshape(unique(design_table.P).', 1, []), 'T_grid', reshape(unique(design_table.T).', 1, []), ...
    'ns_search_min', min(design_table.Ns), 'ns_search_max', max(design_table.Ns)));
cache_record = struct( ...
    'cache_file', string(cache_file), ...
    'manifest_csv', "", ...
    'cache_hit', false, ...
    'reason', string(local_getfield_or(loaded, 'reason', "fresh_evaluation")), ...
    'family_name', string(family_name), ...
    'h_km', h_km);
artifacts = save_mb_cache_with_manifest(cache_file, struct('run', run), manifest);
cache_record.manifest_csv = artifacts.manifest_csv;
run.cache_info = cache_record;
end

function run = local_empty_run()
run = struct( ...
    'h_km', NaN, ...
    'family_name', "", ...
    'design_table', table(), ...
    'eval_table', table(), ...
    'feasible_table', table(), ...
    'aggregate', struct(), ...
    'summary', struct(), ...
    'cache_info', struct(), ...
    'incremental_search_history', table(), ...
    'incremental_seed_info', struct());
end

function summary = local_build_summary(eval_table, feasible_table, sensor_group, family_name)
summary = struct( ...
    'family_name', string(family_name), ...
    'sensor_group', string(sensor_group.name), ...
    'sensor_label', string(sensor_group.sensor_label), ...
    'max_off_boresight_deg', sensor_group.max_off_boresight_deg, ...
    'sigma_angle_arcsec', sensor_group.angle_resolution_arcsec, ...
    'sigma_angle_rad', sensor_group.angle_resolution_rad, ...
    'num_total', height(eval_table), ...
    'num_feasible', height(feasible_table), ...
    'feasible_ratio', local_safe_divide(height(feasible_table), height(eval_table)), ...
    'minimum_feasible_Ns', local_min_or_missing(feasible_table, 'Ns'), ...
    'best_joint_margin', local_max_or_nan(feasible_table, 'joint_margin'), ...
    'source_stage', "Stage09");
end

function [seed_hit, seed_run, seed_record] = local_find_incremental_seed(cache_root, target_manifest, input_spec, target_design_table)
seed_hit = false;
seed_run = struct();
seed_record = struct('cache_file', "", 'manifest_csv', "", 'cache_hit', true, 'reason', "", 'family_name', "", 'h_km', NaN);
listing = dir(fullfile(cache_root, '*.mat'));
if isempty(listing)
    return;
end

target_base_spec = input_spec;
target_base_spec.search_domain = struct();
target_base_hash = compute_mb_cache_input_hash(target_base_spec);
best_count = 0;
best_file = "";
best_manifest_csv = "";
for idx = 1:numel(listing)
    data = load(fullfile(listing(idx).folder, listing(idx).name), 'cache_manifest', 'cache_payload');
    if ~isfield(data, 'cache_manifest') || ~isfield(data, 'cache_payload') || ~isfield(data.cache_payload, 'run')
        continue;
    end
    manifest = data.cache_manifest;
    if string(local_getfield_or(manifest, 'cache_namespace', "")) ~= string(local_getfield_or(target_manifest, 'cache_namespace', ""))
        continue;
    end
    candidate_spec = local_getfield_or(manifest, 'input_spec', struct());
    candidate_spec.search_domain = struct();
    if string(compute_mb_cache_input_hash(candidate_spec)) ~= string(target_base_hash)
        continue;
    end
    candidate_run = data.cache_payload.run;
    if isempty(candidate_run) || isempty(local_getfield_or(candidate_run, 'design_table', table()))
        continue;
    end
    if height(candidate_run.design_table) >= height(target_design_table)
        continue;
    end
    [is_subset, ~] = ismember(candidate_run.design_table(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'}), target_design_table(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'}), 'rows');
    if ~all(is_subset)
        continue;
    end
    if height(candidate_run.design_table) > best_count
        best_count = height(candidate_run.design_table);
        best_file = string(fullfile(listing(idx).folder, listing(idx).name));
        best_manifest_csv = replace(best_file, ".mat", ".csv");
        seed_run = candidate_run;
        seed_hit = true;
    end
end

if seed_hit
    seed_record.cache_file = best_file;
    seed_record.manifest_csv = best_manifest_csv;
    seed_record.reason = "compatible_subset_seed";
    seed_record.family_name = string(local_getfield_or(seed_run, 'family_name', ""));
    seed_record.h_km = local_getfield_or(seed_run, 'h_km', NaN);
end
end

function value = local_min_or_missing(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = missing;
    return;
end
value = min(T.(field_name), [], 'omitnan');
if ~isfinite(value)
    value = missing;
end
end

function value = local_max_or_nan(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
value = max(T.(field_name), [], 'omitnan');
end

function value = local_safe_divide(a, b)
if b == 0
    value = 0;
else
    value = a / b;
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
