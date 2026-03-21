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
cache_records = repmat(struct('cache_file', "", 'manifest_csv', "", 'cache_hit', false, 'reason', "", 'family_name', "", 'h_km', NaN, 'cache_hit_count', 0, 'fresh_evaluation_count', 0), 0, 1);
cache_hits = 0;
fresh_evaluations = 0;
for idx_family = 1:numel(legacy_cfg.family_set)
    family_name = legacy_cfg.family_set{idx_family};
    for idx_h = 1:numel(legacy_cfg.heights_to_run)
        h_km = legacy_cfg.heights_to_run(idx_h);
        search_domain = local_search_domain_for_height(legacy_cfg, h_km);
        expansion = expand_mb_search_domain_iteratively(search_domain, ...
            @(domain, iteration) local_build_design_table_for_domain(domain, legacy_cfg, h_km, "legacyDG_expand_" + iteration), ...
            @(domain, design_table, iteration, action, action_reason) local_evaluate_domain_iteration( ...
                cfg_sensor, legacy_cfg, sensor_group, semantic_inputs, family_name, h_km, domain, design_table, ...
                cache_root, iteration, action, action_reason), ...
            struct('semantic_mode', "legacyDG", 'sensor_group', sensor_group.name, ...
                'family_name', family_name, 'height_km', h_km));
        run = expansion.run;
        cache_record = local_build_expansion_cache_record(cache_root, family_name, h_km, expansion);
        cache_records(end + 1, 1) = cache_record; %#ok<AGROW>
        cache_hits = cache_hits + local_getfield_or(cache_record, 'cache_hit_count', double(local_getfield_or(cache_record, 'cache_hit', false)));
        fresh_evaluations = fresh_evaluations + local_getfield_or(cache_record, 'fresh_evaluation_count', double(~local_getfield_or(cache_record, 'cache_hit', false)));
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
meta = cfg.milestones.MB_semantic_compare;
legacy_cfg = struct();
legacy_cfg.sensor_group = char(string(local_getfield_or(options, 'sensor_group', 'baseline')));
legacy_cfg.heights_to_run = reshape(local_getfield_or(options, 'heights_to_run', 1000), 1, []);
legacy_cfg.i_grid_deg = reshape(local_getfield_or(options, 'i_grid_deg', local_getfield_or(meta, 'i_grid_deg', [30 40 50 60 70 80 90])), 1, []);
legacy_cfg.P_grid = reshape(local_getfield_or(options, 'P_grid', local_getfield_or(meta, 'P_grid', [4 6 8 10 12])), 1, []);
legacy_cfg.T_grid = reshape(local_getfield_or(options, 'T_grid', local_getfield_or(meta, 'T_grid', [4 6 8 10 12 16])), 1, []);
legacy_cfg.F_fixed = local_getfield_or(options, 'F_fixed', 1);
legacy_cfg.family_set = local_resolve_family_set(local_getfield_or(options, 'family_set', {'nominal'}));
legacy_cfg.use_parallel = logical(local_getfield_or(options, 'use_parallel', true));
legacy_cfg.parallel_policy = resolve_mb_parallel_policy(local_getfield_or(options, 'parallel_policy', struct('parallel_policy', 'off')));
legacy_cfg.force_rebuild_inputs = logical(local_getfield_or(options, 'force_rebuild_inputs', false));
legacy_cfg.cache_profile = local_getfield_or(options, 'cache_profile', cfg.milestones.MB_semantic_compare.cache_profile);
legacy_cfg.cache_namespace = string(local_getfield_or(options, 'cache_namespace', "mb_legacyDG"));
legacy_cfg.search_domain = local_getfield_or(meta, 'search_domain', struct());
if isstruct(local_getfield_or(options, 'search_domain', struct())) && ~isempty(fieldnames(local_getfield_or(options, 'search_domain', struct())))
    legacy_cfg.search_domain = milestone_common_merge_structs(legacy_cfg.search_domain, local_getfield_or(options, 'search_domain', struct()));
end
legacy_cfg.search_domain.height_grid_km = reshape(legacy_cfg.heights_to_run, 1, []);
legacy_cfg.search_domain.inclination_grid_deg = reshape(legacy_cfg.i_grid_deg, 1, []);
legacy_cfg.search_domain.P_grid = reshape(legacy_cfg.P_grid, 1, []);
legacy_cfg.search_domain.T_grid = reshape(legacy_cfg.T_grid, 1, []);
end

function [run, cache_record] = local_run_or_load_cache(cfg_sensor, legacy_cfg, sensor_group, semantic_inputs, family_name, h_km, design_table, cache_root, search_domain, iteration, action, action_reason)
if nargin < 9 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 10
    iteration = 1;
end
if nargin < 11 || strlength(string(action)) == 0
    action = "fresh_evaluation";
end
if nargin < 12 || strlength(string(action_reason)) == 0
    action_reason = "Evaluate the current search-domain design table.";
end
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
        'P_grid', reshape(unique(design_table.P).', 1, []), ...
        'T_grid', reshape(unique(design_table.T).', 1, []), ...
        'F_fixed', legacy_cfg.F_fixed, ...
        'ns_search_min', local_getfield_or(search_domain, 'ns_search_min', local_min_or_missing(design_table, 'Ns')), ...
        'ns_search_max', local_getfield_or(search_domain, 'ns_search_max', local_max_or_missing(design_table, 'Ns'))), ...
    'gamma_req', local_getfield_or(semantic_inputs, 'gamma_req', NaN), ...
    'nominal_case_count', numel(local_getfield_or(local_getfield_or(semantic_inputs, 'family_inputs', struct()), 'nominal', struct('trajs_in', repmat(struct(), 0, 1))).trajs_in));
manifest = build_mb_cache_manifest("semantic_eval", mfilename, input_spec, struct( ...
    'cache_namespace', legacy_cfg.cache_namespace, ...
    'semantic_mode', "legacyDG", ...
    'sensor_group_name', sensor_group.name, ...
    'sensor_params', input_spec.sensor_params, ...
    'search_domain', input_spec.search_domain, ...
    'search_profile_name', local_getfield_or(cfg_sensor.milestones.MB_semantic_compare, 'resolved_search_profile', local_getfield_or(cfg_sensor.milestones.MB_semantic_compare, 'search_profile', "")), ...
    'profile_mode', local_getfield_or(cfg_sensor.milestones.MB_semantic_compare, 'search_profile_mode', ""), ...
    'Ns_grid', [local_getfield_or(search_domain, 'ns_search_min', NaN), local_getfield_or(search_domain, 'ns_search_max', NaN), local_getfield_or(search_domain, 'ns_search_step', NaN)], ...
    'P_grid', reshape(unique(design_table.P).', 1, []), ...
    'T_grid', reshape(unique(design_table.T).', 1, []), ...
    'expand_blocks', local_getfield_or(cfg_sensor.milestones.MB_semantic_compare, 'Ns_expand_blocks', []), ...
    'Ns_hard_max', local_getfield_or(cfg_sensor.milestones.MB_semantic_compare, 'Ns_hard_max', NaN), ...
    'sensor_propagation_version', "sensor_group_v2", ...
    'semantic_version', string(local_getfield_or(legacy_cfg.cache_profile, 'semantic_version', "mb-semantic-v1")), ...
    'figure_version', string(local_getfield_or(legacy_cfg.cache_profile, 'figure_version', "mb-figure-v1")), ...
    'height_km', h_km, ...
    'family_name', family_name, ...
    'cache_tag', local_getfield_or(legacy_cfg.cache_profile, 'tag', "mb_default"), ...
    'compatible_with_plot_only_changes', true, ...
    'compatible_with_export_only_changes', true));
cache_file = fullfile(cache_root, sprintf('mb_legacydg_%s_h%d_%s_%s.mat', ...
    char(string(family_name)), round(h_km), char(string(sensor_group.name)), char(manifest.input_hash)));
reuse_semantic_cache = logical(local_getfield_or(legacy_cfg.cache_profile, 'reuse_semantic_eval', true));
loaded = struct('reuse', false, 'reason', "cache_disabled", 'payload', struct(), 'manifest_csv', "");
if reuse_semantic_cache
    loaded = should_reuse_mb_semantic_cache(cache_file, manifest);
end

if loaded.reuse
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
        struct('iteration', iteration, 'semantic_mode', "legacyDG", 'sensor_group', sensor_group.name, ...
            'family_name', family_name, 'height_km', h_km, 'action', string(action), 'stop_reason', "incremental_merge_completed"));

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
    artifacts = write_mb_cache_manifest(cache_file, struct('run', run), manifest);
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
    'iteration', iteration, 'semantic_mode', "legacyDG", 'sensor_group', sensor_group.name, 'family_name', family_name, ...
    'height_km', h_km, 'action', string(action), 'action_reason', string(action_reason), 'stop_reason', "initial_domain", 'cache_seed_hit', false, ...
    'previous_design_count', 0, 'added_design_count', height(design_table), 'merged_design_count', height(design_table), ...
    'P_grid', reshape(unique(design_table.P).', 1, []), 'T_grid', reshape(unique(design_table.T).', 1, []), ...
    'ns_search_min', local_getfield_or(search_domain, 'ns_search_min', min(design_table.Ns)), ...
    'ns_search_max', local_getfield_or(search_domain, 'ns_search_max', max(design_table.Ns))));
cache_record = struct( ...
    'cache_file', string(cache_file), ...
    'manifest_csv', "", ...
    'cache_hit', false, ...
    'reason', string(local_getfield_or(loaded, 'reason', "fresh_evaluation")), ...
    'family_name', string(family_name), ...
    'h_km', h_km);
artifacts = write_mb_cache_manifest(cache_file, struct('run', run), manifest);
cache_record.manifest_csv = artifacts.manifest_csv;
run.cache_info = cache_record;
end

function semantic_inputs = local_prepare_semantic_inputs(cfg_sensor, legacy_cfg)
semantic_inputs = struct();
semantic_inputs.cfg = cfg_sensor;
semantic_inputs.sensor_group = legacy_cfg.sensor_group;
paths = mb_output_paths(cfg_sensor, cfg_sensor.milestones.MB_semantic_compare.milestone_id, cfg_sensor.milestones.MB_semantic_compare.title);
semantic_inputs.family_inputs = local_load_family_inputs(cfg_sensor, legacy_cfg, paths);
semantic_inputs.stage02_file = string(local_getfield_or(semantic_inputs.family_inputs, 'stage02_file', ""));
semantic_inputs.stage04_file = string(local_getfield_or(semantic_inputs.family_inputs, 'stage04_file', ""));
semantic_inputs.gamma_req = semantic_inputs.family_inputs.gamma_req;
end

function family_inputs = local_load_family_inputs(cfg_sensor, legacy_cfg, paths)
family_inputs = struct();

cfg_stage = cfg_sensor;
cfg_stage.stage01.make_plot = false;
cfg_stage.stage02.make_plot = false;
cfg_stage.stage02.make_plot_3d = false;
cfg_stage.stage03.make_plot = false;
cfg_stage.stage04.make_plot = false;
cfg_stage = local_configure_isolated_stage_io(cfg_stage, paths, legacy_cfg.sensor_group);
seed_info = local_seed_stage01_cache(cfg_sensor, cfg_stage);
[reuse_hit, stage02_out, stage04_out] = local_try_load_cached_stage_input_chain(cfg_stage, legacy_cfg, seed_info);
if ~reuse_hit
    run_mode = local_run_mode(legacy_cfg.use_parallel);
    stage02_out = stage02_hgv_nominal(cfg_stage, struct('mode', run_mode));
    stage03_visibility_pipeline(cfg_stage, struct('mode', run_mode));
    stage04_out = stage04_window_worstcase(cfg_stage, struct('mode', run_mode));
    local_save_stage_input_chain_manifest(cfg_stage, legacy_cfg, seed_info, stage02_out, stage04_out);
end

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

function cfg_stage = local_configure_isolated_stage_io(cfg_stage, paths, sensor_group_name)
sensor_tag = char(matlab.lang.makeValidName(char(string(sensor_group_name))));
stage_root = fullfile(paths.cache, 'stage05_inputs', sensor_tag);
cfg_stage.paths.stage_outputs = fullfile(stage_root, 'stage_outputs');
cfg_stage.paths.log_outputs = fullfile(stage_root, 'logs');
cfg_stage.paths.cache = fullfile(cfg_stage.paths.stage_outputs, 'stage00', 'cache');
cfg_stage.paths.logs = fullfile(cfg_stage.paths.log_outputs, 'stage00');
cfg_stage.paths.figs = fullfile(cfg_stage.paths.stage_outputs, 'stage00', 'figs');
cfg_stage.paths.tables = fullfile(cfg_stage.paths.stage_outputs, 'stage00', 'tables');
ensure_dir(cfg_stage.paths.stage_outputs);
ensure_dir(cfg_stage.paths.log_outputs);
end

function seed_info = local_seed_stage01_cache(cfg_source, cfg_target)
source_listing = find_stage_cache_files(cfg_source, 'stage01_scenario_disk_*.mat');
if isempty(source_listing)
    error('MB legacyDG wrapper could not locate any Stage01 cache to seed the isolated Stage02/03/04 pipeline.');
end
[~, idx_latest] = max([source_listing.datenum]);
source_file = fullfile(source_listing(idx_latest).folder, source_listing(idx_latest).name);

target_stage01_cache = fullfile(cfg_target.paths.stage_outputs, 'stage01', 'cache');
ensure_dir(target_stage01_cache);
target_file = fullfile(target_stage01_cache, source_listing(idx_latest).name);
if exist(target_file, 'file') ~= 2
    copyfile(source_file, target_file);
else
    source_info = dir(source_file);
    target_info = dir(target_file);
    if isempty(target_info) || source_info.bytes ~= target_info.bytes
        copyfile(source_file, target_file);
    end
end

source_info = dir(source_file);
seed_info = struct( ...
    'source_file', string(source_file), ...
    'target_file', string(target_file), ...
    'source_bytes', source_info.bytes, ...
    'source_datenum', source_info.datenum);
end

function [reuse_hit, stage02_out, stage04_out] = local_try_load_cached_stage_input_chain(cfg_stage, legacy_cfg, seed_info)
reuse_hit = false;
stage02_out = struct();
stage04_out = struct();
if logical(local_getfield_or(legacy_cfg, 'force_rebuild_inputs', false))
    return;
end

manifest_path = local_stage_input_manifest_path(cfg_stage);
if exist(manifest_path, 'file') ~= 2
    return;
end

tmp = load(manifest_path, 'manifest');
if ~isfield(tmp, 'manifest')
    return;
end
manifest = tmp.manifest;
if string(local_getfield_or(manifest, 'version', "")) ~= "mb_stage05_input_chain_v1"
    return;
end
if string(local_getfield_or(manifest, 'sensor_group', "")) ~= string(local_getfield_or(legacy_cfg, 'sensor_group', ""))
    return;
end
if string(local_getfield_or(manifest, 'source_stage01_file', "")) ~= string(seed_info.source_file)
    return;
end
if double(local_getfield_or(manifest, 'source_stage01_bytes', NaN)) ~= double(seed_info.source_bytes)
    return;
end
if abs(double(local_getfield_or(manifest, 'source_stage01_datenum', NaN)) - double(seed_info.source_datenum)) > 1e-9
    return;
end

stage02_file = char(string(local_getfield_or(manifest, 'stage02_cache_file', "")));
stage04_file = char(string(local_getfield_or(manifest, 'stage04_cache_file', "")));
if exist(stage02_file, 'file') ~= 2 || exist(stage04_file, 'file') ~= 2
    return;
end

tmp_stage02 = load(stage02_file, 'out');
tmp_stage04 = load(stage04_file, 'out');
if ~isfield(tmp_stage02, 'out') || ~isfield(tmp_stage04, 'out')
    return;
end

stage02_out = tmp_stage02.out;
stage04_out = tmp_stage04.out;
reuse_hit = true;
end

function local_save_stage_input_chain_manifest(cfg_stage, legacy_cfg, seed_info, stage02_out, stage04_out)
stage04_cache_file = string(local_getfield_or(stage04_out, 'cache_file', ""));
if strlength(stage04_cache_file) == 0
    stage04_cache_file = local_find_latest_stage04_file(cfg_stage);
end
manifest = struct( ...
    'version', "mb_stage05_input_chain_v1", ...
    'sensor_group', string(local_getfield_or(legacy_cfg, 'sensor_group', "")), ...
    'source_stage01_file', string(seed_info.source_file), ...
    'source_stage01_bytes', double(seed_info.source_bytes), ...
    'source_stage01_datenum', double(seed_info.source_datenum), ...
    'stage02_cache_file', string(local_getfield_or(stage02_out, 'cache_file', "")), ...
    'stage04_cache_file', stage04_cache_file, ...
    'saved_at', string(datestr(now, 'yyyy-mm-dd HH:MM:SS')));
save(local_stage_input_manifest_path(cfg_stage), 'manifest', '-v7');
end

function manifest_path = local_stage_input_manifest_path(cfg_stage)
manifest_path = fullfile(fileparts(cfg_stage.paths.stage_outputs), 'stage05_input_manifest.mat');
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
    'incremental_seed_info', struct(), ...
    'expansion_state', struct());
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

function value = local_max_or_missing(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = missing;
    return;
end
value = max(T.(field_name), [], 'omitnan');
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

function search_domain = local_search_domain_for_height(legacy_cfg, h_km)
search_domain = legacy_cfg.search_domain;
search_domain.height_grid_km = h_km;
search_domain.h_km = h_km;
search_domain.P_grid = reshape(local_getfield_or(search_domain, 'P_grid', legacy_cfg.P_grid), 1, []);
search_domain.T_grid = reshape(local_getfield_or(search_domain, 'T_grid', legacy_cfg.T_grid), 1, []);
search_domain.inclination_grid_deg = reshape(local_getfield_or(search_domain, 'inclination_grid_deg', legacy_cfg.i_grid_deg), 1, []);
search_domain.allow_auto_expand_upper = logical(local_getfield_or(search_domain, 'Ns_allow_expand', false));
plan = build_mb_ns_search_plan(search_domain);
search_domain.Ns_initial_range = [plan.initial.ns_min, plan.initial.ns_step, plan.initial.ns_max];
[search_domain, ~] = extend_mb_ns_grid_by_policy(search_domain, plan.initial, struct(), struct());
end

function design_table = local_build_design_table_for_domain(search_domain, legacy_cfg, h_km, slice_source)
design_table = build_mb_fixed_h_design_table( ...
    h_km, ...
    reshape(local_getfield_or(search_domain, 'inclination_grid_deg', legacy_cfg.i_grid_deg), 1, []), ...
    reshape(local_getfield_or(search_domain, 'P_grid', legacy_cfg.P_grid), 1, []), ...
    reshape(local_getfield_or(search_domain, 'T_grid', legacy_cfg.T_grid), 1, []), ...
    legacy_cfg.F_fixed, slice_source);
ns_min = local_getfield_or(search_domain, 'ns_search_min', NaN);
ns_max = local_getfield_or(search_domain, 'ns_search_max', NaN);
if isfinite(ns_min)
    design_table = design_table(design_table.Ns >= ns_min, :);
end
if isfinite(ns_max)
    design_table = design_table(design_table.Ns <= ns_max, :);
end
end

function eval_output = local_evaluate_domain_iteration(cfg_sensor, legacy_cfg, sensor_group, semantic_inputs, family_name, h_km, search_domain, design_table, cache_root, iteration, action, action_reason)
[run, cache_record] = local_run_or_load_cache(cfg_sensor, legacy_cfg, sensor_group, semantic_inputs, family_name, h_km, design_table, cache_root, search_domain, iteration, action, action_reason);
eval_output = struct('run', run, 'cache_record', cache_record);
end

function cache_record = local_build_expansion_cache_record(cache_root, family_name, h_km, expansion)
records = local_getfield_or(expansion, 'cache_records', repmat(struct('cache_hit', false), 0, 1));
cache_record = struct( ...
    'cache_file', string(fullfile(cache_root, sprintf('mb_legacydg_%s_h%d_expansion.mat', char(string(family_name)), round(h_km)))), ...
    'manifest_csv', "", ...
    'cache_hit', false, ...
    'reason', string(local_getfield_or(expansion, 'stop_reason', "")), ...
    'family_name', string(family_name), ...
    'h_km', h_km, ...
    'cache_hit_count', 0, ...
    'fresh_evaluation_count', 0);
if isempty(records)
    return;
end
cache_record.manifest_csv = string(local_getfield_or(records(end), 'manifest_csv', ""));
cache_record.cache_hit = any(arrayfun(@(r) logical(local_getfield_or(r, 'cache_hit', false)), records));
cache_record.cache_hit_count = sum(arrayfun(@(r) double(logical(local_getfield_or(r, 'cache_hit', false))), records));
cache_record.fresh_evaluation_count = numel(records) - cache_record.cache_hit_count;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
