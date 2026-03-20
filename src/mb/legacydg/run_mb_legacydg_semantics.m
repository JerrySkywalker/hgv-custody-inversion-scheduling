function out = run_mb_legacydg_semantics(cfg, options)
%RUN_MB_LEGACYDG_SEMANTICS Run MB legacyDG semantics through Stage05-compatible wrappers.

mb_safe_startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(options)
    options = struct();
end

legacy_cfg = local_normalize_options(cfg, options);
[cfg_sensor, sensor_group] = apply_sensor_param_group_to_cfg(cfg, legacy_cfg.sensor_group);
semantic_inputs = local_prepare_semantic_inputs(cfg_sensor, legacy_cfg);
paths = mb_output_paths(cfg_sensor, cfg_sensor.milestones.MB_semantic_compare.milestone_id, cfg_sensor.milestones.MB_semantic_compare.title);
cache_root = fullfile(paths.cache, 'semantic', 'legacyDG');
ensure_dir(cache_root);

run_bank = repmat(local_empty_run(), 0, 1);
cache_records = repmat(struct('cache_file', "", 'manifest_csv', "", 'cache_hit', false, 'reason', "", 'family_name', "", 'h_km', NaN), 0, 1);
cache_hits = 0;
fresh_evaluations = 0;
for idx_family = 1:numel(legacy_cfg.family_set)
    family_name = legacy_cfg.family_set{idx_family};
    for idx_h = 1:numel(legacy_cfg.heights_to_run)
        h_km = legacy_cfg.heights_to_run(idx_h);
        design_table = build_mb_fixed_h_design_table( ...
            h_km, legacy_cfg.i_grid_deg, legacy_cfg.P_grid, legacy_cfg.T_grid, legacy_cfg.F_fixed, "legacyDG_wrapper");
        [run, cache_record] = local_run_or_load_cache(cfg_sensor, legacy_cfg, sensor_group, semantic_inputs, family_name, h_km, design_table, cache_root);
        cache_records(end + 1, 1) = cache_record; %#ok<AGROW>
        cache_hits = cache_hits + double(cache_record.cache_hit);
        fresh_evaluations = fresh_evaluations + double(~cache_record.cache_hit);
        run_bank(end + 1, 1) = run; %#ok<AGROW>
    end
end

out = struct();
out.mode = "legacyDG";
out.sensor_group = sensor_group;
out.options = legacy_cfg;
out.runs = run_bank;
out.inputs = rmfield(semantic_inputs, {'family_inputs'});
out.cache_records = cache_records;
out.summary = struct( ...
    'mode', "legacyDG", ...
    'sensor_group', sensor_group.name, ...
    'sensor_label', sensor_group.sensor_label, ...
    'family_set', {legacy_cfg.family_set}, ...
    'heights_to_run', legacy_cfg.heights_to_run, ...
    'total_run_count', numel(run_bank), ...
    'cache_hits', cache_hits, ...
    'fresh_evaluations', fresh_evaluations, ...
    'interpretation_note', "legacyDG keeps the original Stage05 D_G-driven feasibility and pass-ratio semantics inside the MB comparison shell.");
end

function legacy_cfg = local_normalize_options(cfg, options)
meta = cfg.milestones.MB;
legacy_cfg = struct();
legacy_cfg.sensor_group = char(string(local_getfield_or(options, 'sensor_group', 'baseline')));
legacy_cfg.heights_to_run = reshape(local_getfield_or(options, 'heights_to_run', 1000), 1, []);
legacy_cfg.i_grid_deg = reshape(local_getfield_or(options, 'i_grid_deg', meta.fixed_h_exploration_i_deg), 1, []);
legacy_cfg.P_grid = reshape(local_getfield_or(options, 'P_grid', meta.fixed_h_exploration_P), 1, []);
legacy_cfg.T_grid = reshape(local_getfield_or(options, 'T_grid', meta.fixed_h_exploration_T), 1, []);
legacy_cfg.F_fixed = local_getfield_or(options, 'F_fixed', 1);
legacy_cfg.family_set = local_resolve_family_set(local_getfield_or(options, 'family_set', {'nominal'}));
legacy_cfg.use_parallel = logical(local_getfield_or(options, 'use_parallel', true));
legacy_cfg.parallel_policy = resolve_mb_parallel_policy(local_getfield_or(options, 'parallel_policy', struct('parallel_policy', 'off')));
legacy_cfg.force_rebuild_inputs = logical(local_getfield_or(options, 'force_rebuild_inputs', false));
legacy_cfg.cache_profile = local_getfield_or(options, 'cache_profile', cfg.milestones.MB_semantic_compare.cache_profile);
legacy_cfg.cache_namespace = string(local_getfield_or(options, 'cache_namespace', "mb_legacyDG"));
end

function [run, cache_record] = local_run_or_load_cache(cfg_sensor, legacy_cfg, sensor_group, semantic_inputs, family_name, h_km, design_table, cache_root)
input_spec = struct( ...
    'semantic_mode', "legacyDG", ...
    'family_name', string(family_name), ...
    'sensor_group', string(sensor_group.name), ...
    'sensor_params', struct( ...
        'max_off_boresight_deg', sensor_group.max_off_boresight_deg, ...
        'sigma_angle_arcsec', sensor_group.angle_resolution_arcsec, ...
        'sigma_angle_rad', sensor_group.angle_resolution_rad), ...
    'search_domain', struct( ...
        'height_km', h_km, ...
        'inclination_grid_deg', reshape(legacy_cfg.i_grid_deg, 1, []), ...
        'P_grid', reshape(legacy_cfg.P_grid, 1, []), ...
        'T_grid', reshape(legacy_cfg.T_grid, 1, []), ...
        'F_fixed', legacy_cfg.F_fixed), ...
    'gamma_req', local_getfield_or(semantic_inputs, 'gamma_req', NaN), ...
    'nominal_case_count', numel(local_getfield_or(local_getfield_or(semantic_inputs, 'family_inputs', struct()), 'nominal', struct('trajs_in', repmat(struct(), 0, 1))).trajs_in));
manifest = build_mb_cache_manifest("semantic_eval", mfilename, input_spec, struct( ...
    'cache_namespace', legacy_cfg.cache_namespace, ...
    'semantic_mode', "legacyDG", ...
    'sensor_group_name', sensor_group.name, ...
    'sensor_params', input_spec.sensor_params, ...
    'search_domain', input_spec.search_domain, ...
    'profile_mode', local_getfield_or(cfg_sensor.milestones.MB_semantic_compare, 'search_profile_mode', ""), ...
    'height_km', h_km, ...
    'family_name', family_name, ...
    'cache_tag', local_getfield_or(legacy_cfg.cache_profile, 'tag', "mb_default"), ...
    'compatible_with_plot_only_changes', true, ...
    'compatible_with_export_only_changes', true));
cache_file = fullfile(cache_root, sprintf('mb_legacydg_%s_h%d_%s_%s.mat', ...
    char(string(family_name)), round(h_km), char(string(sensor_group.name)), char(manifest.input_hash)));
reuse_semantic_cache = logical(local_getfield_or(legacy_cfg.cache_profile, 'reuse_semantic_eval', true));
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
        @(added_designs) evaluate_design_pool_with_stage05_semantics(cfg_sensor, added_designs, family_name, semantic_inputs, struct( ...
            'sensor_group', sensor_group.name, ...
            'family_name', family_name, ...
            'parallel_policy', legacy_cfg.parallel_policy, ...
            'use_parallel', legacy_cfg.use_parallel)), ...
        @(merged_eval) aggregate_stage05_semantics_results(merged_eval, h_km, family_name, sensor_group.name, legacy_cfg.i_grid_deg), ...
        struct('iteration', 1, 'semantic_mode', "legacyDG", 'sensor_group', sensor_group.name, ...
            'family_name', family_name, 'height_km', h_km, 'action', "incremental_expand", 'stop_reason', "incremental_merge_completed"));

    run = local_empty_run();
    run.h_km = h_km;
    run.family_name = string(family_name);
    run.design_table = incremental.design_table;
    run.eval_table = incremental.eval_table;
    run.feasible_table = incremental.feasible_table;
    run.aggregate = incremental.aggregate;
    run.summary = local_build_summary(run.eval_table, run.feasible_table, semantic_inputs, family_name);
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

eval_out = evaluate_design_pool_with_stage05_semantics(cfg_sensor, design_table, family_name, semantic_inputs, struct( ...
    'sensor_group', sensor_group.name, ...
    'family_name', family_name, ...
    'parallel_policy', legacy_cfg.parallel_policy, ...
    'use_parallel', legacy_cfg.use_parallel));
agg_out = aggregate_stage05_semantics_results(eval_out.eval_table, h_km, family_name, sensor_group.name, legacy_cfg.i_grid_deg);

run = local_empty_run();
run.h_km = h_km;
run.family_name = string(family_name);
run.design_table = design_table;
run.eval_table = eval_out.eval_table;
run.feasible_table = eval_out.feasible_table;
run.aggregate = agg_out;
run.summary = eval_out.summary;
run.incremental_search_history = build_mb_incremental_search_history(struct( ...
    'iteration', 1, 'semantic_mode', "legacyDG", 'sensor_group', sensor_group.name, 'family_name', family_name, ...
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

function semantic_inputs = local_prepare_semantic_inputs(cfg_sensor, legacy_cfg)
semantic_inputs = struct();
semantic_inputs.cfg = cfg_sensor;
semantic_inputs.sensor_group = legacy_cfg.sensor_group;
semantic_inputs.family_inputs = local_load_family_inputs(cfg_sensor, legacy_cfg);
semantic_inputs.stage02_file = string(local_getfield_or(semantic_inputs.family_inputs, 'stage02_file', ""));
semantic_inputs.stage04_file = string(local_getfield_or(semantic_inputs.family_inputs, 'stage04_file', ""));
semantic_inputs.gamma_req = semantic_inputs.family_inputs.gamma_req;
end

function family_inputs = local_load_family_inputs(cfg_sensor, legacy_cfg)
family_inputs = struct();

cfg_stage = cfg_sensor;
cfg_stage.stage01.make_plot = false;
cfg_stage.stage02.make_plot = false;
cfg_stage.stage02.make_plot_3d = false;
cfg_stage.stage03.make_plot = false;
cfg_stage.stage04.make_plot = false;

run_mode = local_run_mode(legacy_cfg.use_parallel);
stage02_out = stage02_hgv_nominal(cfg_stage, struct('mode', run_mode));
stage03_visibility_pipeline(cfg_stage, struct('mode', run_mode));
stage04_out = stage04_window_worstcase(cfg_stage, struct('mode', run_mode));

family_inputs.stage02_file = string(local_getfield_or(stage02_out, 'cache_file', ""));
family_inputs.stage04_file = local_find_latest_stage04_file(cfg_stage);
family_inputs.gamma_req = stage04_out.summary.gamma_meta.gamma_req;

trajbank = stage02_out.trajbank;
families = fieldnames(trajbank);
for idx = 1:numel(families)
    family_name = families{idx};
    trajs_in = trajbank.(family_name);
    family_inputs.(family_name) = struct( ...
        'trajs_in', trajs_in, ...
        'hard_order', local_build_hard_order(trajs_in, stage04_out, family_name), ...
        'eval_context', local_build_eval_context(trajs_in, cfg_stage));
end
end

function stage04_file = local_find_latest_stage04_file(cfg_stage)
listing = find_stage_cache_files(cfg_stage, 'stage04_window_worstcase_*.mat');
if isempty(listing)
    stage04_file = "";
    return;
end
[~, idx_latest] = max([listing.datenum]);
stage04_file = string(fullfile(listing(idx_latest).folder, listing(idx_latest).name));
end

function hard_order = local_build_hard_order(trajs_in, stage04_out, family_name)
hard_order = (1:numel(trajs_in)).';
if ~isfield(stage04_out, 'summary') || ~isfield(stage04_out.summary, 'margin') || ~isfield(stage04_out.summary.margin, 'case_table')
    return;
end

tab4 = stage04_out.summary.margin.case_table;
required_vars = {'case_ids', 'D_G', 'families'};
if isempty(tab4) || ~all(ismember(required_vars, tab4.Properties.VariableNames))
    return;
end

traj_case_ids = strings(numel(trajs_in), 1);
for idx = 1:numel(trajs_in)
    traj_case_ids(idx) = string(trajs_in(idx).case.case_id);
end

family_rows = strcmp(string(tab4.families), string(family_name));
tab_family = tab4(family_rows, :);
if isempty(tab_family)
    return;
end

[~, ord] = sort(tab_family.D_G, 'ascend');
hard_ids = string(tab_family.case_ids(ord));
hard_order_tmp = nan(numel(hard_ids), 1);
for idx = 1:numel(hard_ids)
    hit = find(traj_case_ids == hard_ids(idx), 1);
    if ~isempty(hit)
        hard_order_tmp(idx) = hit;
    end
end
hard_order_tmp = hard_order_tmp(isfinite(hard_order_tmp));
if numel(hard_order_tmp) == numel(trajs_in)
    hard_order = hard_order_tmp;
end
end

function eval_context = local_build_eval_context(trajs_in, cfg_stage)
t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
eval_context = struct();
eval_context.t_s_common = (0:cfg_stage.stage02.Ts_s:max(t_end_all)).';
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

function summary = local_build_summary(eval_table, feasible_table, semantic_inputs, family_name)
summary = struct( ...
    'design_count', height(eval_table), ...
    'feasible_count', height(feasible_table), ...
    'minimum_feasible_Ns', local_min_or_missing(feasible_table, 'Ns'), ...
    'gamma_req', local_getfield_or(semantic_inputs, 'gamma_req', NaN), ...
    'family_name', string(family_name));
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

function family_set = local_resolve_family_set(family_input)
tokens = cellstr(string(family_input));
tokens = cellfun(@(s) lower(strtrim(s)), tokens, 'UniformOutput', false);
if any(strcmp(tokens, 'all'))
    family_set = {'nominal', 'heading', 'critical'};
else
    family_set = unique(tokens, 'stable');
end
end

function mode = local_run_mode(use_parallel)
if use_parallel
    mode = 'parallel';
else
    mode = 'serial';
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
