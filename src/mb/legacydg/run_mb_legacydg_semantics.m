function out = run_mb_legacydg_semantics(cfg, options)
%RUN_MB_LEGACYDG_SEMANTICS Run MB legacyDG semantics through Stage05-compatible wrappers.

startup();

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

run_bank = repmat(local_empty_run(), 0, 1);
for idx_family = 1:numel(legacy_cfg.family_set)
    family_name = legacy_cfg.family_set{idx_family};
    for idx_h = 1:numel(legacy_cfg.heights_to_run)
        h_km = legacy_cfg.heights_to_run(idx_h);
        design_table = build_mb_fixed_h_design_table( ...
            h_km, legacy_cfg.i_grid_deg, legacy_cfg.P_grid, legacy_cfg.T_grid, legacy_cfg.F_fixed, "legacyDG_wrapper");

        eval_out = evaluate_design_pool_with_stage05_semantics(cfg_sensor, design_table, family_name, semantic_inputs, struct( ...
            'sensor_group', sensor_group.name, ...
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
        run_bank(end + 1, 1) = run; %#ok<AGROW>
    end
end

out = struct();
out.mode = "legacyDG";
out.sensor_group = sensor_group;
out.options = legacy_cfg;
out.runs = run_bank;
out.inputs = rmfield(semantic_inputs, {'family_inputs'});
out.summary = struct( ...
    'mode', "legacyDG", ...
    'sensor_group', sensor_group.name, ...
    'sensor_label', sensor_group.sensor_label, ...
    'family_set', {legacy_cfg.family_set}, ...
    'heights_to_run', legacy_cfg.heights_to_run, ...
    'total_run_count', numel(run_bank), ...
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
legacy_cfg.force_rebuild_inputs = logical(local_getfield_or(options, 'force_rebuild_inputs', false));
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
    'summary', struct());
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
