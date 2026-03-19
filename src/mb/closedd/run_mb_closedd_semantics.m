function out = run_mb_closedd_semantics(cfg, options)
%RUN_MB_CLOSEDD_SEMANTICS Run MB closedD semantics through Stage09-compatible wrappers.

startup();

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

run_bank = repmat(local_empty_run(), 0, 1);
for idx_family = 1:numel(closed_cfg.family_set)
    family_name = closed_cfg.family_set{idx_family};
    for idx_h = 1:numel(closed_cfg.heights_to_run)
        h_km = closed_cfg.heights_to_run(idx_h);
        design_table = build_mb_fixed_h_design_table( ...
            h_km, closed_cfg.i_grid_deg, closed_cfg.P_grid, closed_cfg.T_grid, closed_cfg.F_fixed, "closedD_wrapper");

        eval_out = evaluate_design_pool_with_stage09_semantics(cfg_sensor, design_table, family_name, struct( ...
            'sensor_group', sensor_group.name, ...
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
        run_bank(end + 1, 1) = run; %#ok<AGROW>
    end
end

out = struct();
out.mode = "closedD";
out.sensor_group = sensor_group;
out.options = closed_cfg;
out.runs = run_bank;
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
closed_cfg.heading_subset_max = local_getfield_or(options, 'heading_subset_max', cfg.milestones.MB.slice_settings.heading_subset_max);
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

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
