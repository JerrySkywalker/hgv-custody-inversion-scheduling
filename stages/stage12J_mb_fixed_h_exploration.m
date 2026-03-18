function out = stage12J_mb_fixed_h_exploration(cfg, pool, overrides)
%STAGE12J_MB_FIXED_H_EXPLORATION Run Stage05-style fixed-height exploratory MB scans with the current Stage09 truth kernel.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(pool) || ~isstruct(pool)
    error('stage12J_mb_fixed_h_exploration requires cfg and a populated pool struct.');
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

meta = cfg.milestones.MB;
if isstruct(overrides)
    meta = milestone_common_merge_structs(meta, overrides);
end

out = struct();
out.summary = struct('enabled', false);
if ~isfield(meta, 'enable_fixed_h_exploration') || ~logical(meta.enable_fixed_h_exploration)
    return;
end

fixed_cfg = local_fixed_h_cfg(meta, pool);
height_runs = repmat(local_empty_height_run(), numel(fixed_cfg.h_fixed_list), 1);
total_design_count = 0;
total_feasible_count = 0;
total_eval_s = 0;

for idx = 1:numel(fixed_cfg.h_fixed_list)
    h_km = fixed_cfg.h_fixed_list(idx);

    design_table = build_mb_fixed_h_design_table( ...
        h_km, fixed_cfg.i_grid_deg, fixed_cfg.P_grid, fixed_cfg.T_grid, fixed_cfg.F_fixed, "fixed_h_exploration");

    fprintf('[MB][fixed-h] h=%.0f km: evaluating %d nominal designs.\n', h_km, height(design_table));
    t_eval = tic;
    eval_out = evaluate_dense_design_grid_with_stage09(cfg, design_table, struct( ...
        'family_names', "nominal", ...
        'heading_subset_max', fixed_cfg.heading_subset_max, ...
        'use_parallel', true));
    eval_s = toc(t_eval);
    fprintf('[MB][fixed-h] h=%.0f km: Stage09 truth finished in %.2fs.\n', h_km, eval_s);

    nominal_table = eval_out.nominal.full_theta_table;
    feasible_nominal = eval_out.nominal.feasible_theta_table;
    requirement_surface = build_mb_fixed_h_requirement_surface_iP(nominal_table, h_km, fixed_cfg.family_name);
    phasecurve_table = build_mb_fixed_h_passratio_phasecurve(nominal_table, h_km, fixed_cfg.i_grid_deg, fixed_cfg.family_name);
    stage05_passratio_replica = build_mb_fixed_h_passratio_profile_stage05replica(nominal_table, h_km, fixed_cfg.i_grid_deg, fixed_cfg.family_name);
    frontier_table = build_mb_fixed_h_frontier_vs_i(nominal_table, h_km, fixed_cfg.family_name);

    height_runs(idx).h_km = h_km;
    height_runs(idx).design_table = design_table;
    height_runs(idx).eval = eval_out;
    height_runs(idx).requirement_surface_iP = requirement_surface;
    height_runs(idx).passratio_phasecurve = phasecurve_table;
    height_runs(idx).stage05_passratio_replica = stage05_passratio_replica;
    height_runs(idx).frontier_vs_i = frontier_table;
    height_runs(idx).summary = struct( ...
        'design_count', height(design_table), ...
        'feasible_count', height(feasible_nominal), ...
        'minimum_feasible_Ns', local_min_or_nan(feasible_nominal, 'Ns'), ...
        'eval_s', eval_s);

    total_design_count = total_design_count + height(design_table);
    total_feasible_count = total_feasible_count + height(feasible_nominal);
    total_eval_s = total_eval_s + eval_s;
end

out.cfg = fixed_cfg;
out.height_runs = height_runs;
out.summary = struct( ...
    'enabled', true, ...
    'family_name', fixed_cfg.family_name, ...
    'h_fixed_list', fixed_cfg.h_fixed_list, ...
    'i_grid_deg', fixed_cfg.i_grid_deg, ...
    'P_grid', fixed_cfg.P_grid, ...
    'T_grid', fixed_cfg.T_grid, ...
    'F_fixed', fixed_cfg.F_fixed, ...
    'total_design_count', total_design_count, ...
    'total_feasible_count', total_feasible_count, ...
    'total_eval_s', total_eval_s, ...
    'interpretation_note', "This exploratory branch reuses the Stage05-style fixed-height design perspective (coarse global scan over i, P, T) but evaluates all candidate designs with the current Stage09 truth kernel. Therefore, it should be interpreted as an engineering-design exploratory layer, not as a replacement for the formal full-MB minimum-shell definition.");
end

function fixed_cfg = local_fixed_h_cfg(meta, pool)
fixed_cfg = struct();
fixed_cfg.h_fixed_list = reshape(unique(meta.fixed_h_exploration_h_km(:), 'stable'), 1, []);
fixed_cfg.i_grid_deg = reshape(unique(meta.fixed_h_exploration_i_deg(:), 'stable'), 1, []);
fixed_cfg.P_grid = reshape(unique(meta.fixed_h_exploration_P(:), 'stable'), 1, []);
fixed_cfg.T_grid = reshape(unique(meta.fixed_h_exploration_T(:), 'stable'), 1, []);
fixed_cfg.heading_subset_max = meta.slice_settings.heading_subset_max;
fixed_cfg.family_name = "nominal";
fixed_cfg.enable_stage05_passratio_replica = local_getfield_or(meta, 'enable_stage05_passratio_replica', true);
fixed_cfg.F_fixed = meta.fixed_h_exploration_F;
if ~isfinite(fixed_cfg.F_fixed)
    fixed_cfg.F_fixed = pool.baseline_theta.F;
end
end

function value = local_min_or_nan(T, field_name)
value = NaN;
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
value = min(T.(field_name), [], 'omitnan');
end

function run = local_empty_height_run()
run = struct( ...
    'h_km', NaN, ...
    'design_table', table(), ...
    'eval', struct(), ...
    'requirement_surface_iP', struct(), ...
    'passratio_phasecurve', table(), ...
    'stage05_passratio_replica', table(), ...
    'frontier_vs_i', table(), ...
    'summary', struct());
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
