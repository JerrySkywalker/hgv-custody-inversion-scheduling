function out = stage12K_mb_stage05_semantic_reproduction(cfg, overrides)
%STAGE12K_MB_STAGE05_SEMANTIC_REPRODUCTION Reproduce Stage05 nominal-family threshold diagnostics under MB outputs.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

meta = cfg.milestones.MB;
if isstruct(overrides)
    meta = milestone_common_merge_structs(meta, overrides);
end

out = struct();
out.summary = struct('enabled', false);
if ~local_getfield_or(meta, 'enable_stage05_semantic_reproduction', false)
    return;
end

semantic_cfg = local_semantic_cfg(meta);
semantic_inputs = load_mb_stage05_semantic_inputs(struct( ...
    'use_parallel', semantic_cfg.use_parallel, ...
    'force_rebuild', semantic_cfg.force_rebuild_inputs));

height_runs = repmat(local_empty_height_run(), numel(semantic_cfg.h_fixed_list), 1);
total_design_count = 0;
total_feasible_count = 0;
total_eval_s = 0;

for idx = 1:numel(semantic_cfg.h_fixed_list)
    h_km = semantic_cfg.h_fixed_list(idx);
    design_table = build_mb_fixed_h_design_table( ...
        h_km, semantic_cfg.i_grid_deg, semantic_cfg.P_grid, semantic_cfg.T_grid, semantic_cfg.F_fixed, "stage05_semantic_reproduction");

    fprintf('[MB][stage05-sem] h=%.0f km: evaluating %d nominal designs.\n', h_km, height(design_table));
    t_eval = tic;
    eval_out = evaluate_design_grid_with_stage05_semantics(design_table, semantic_inputs, struct( ...
        'use_parallel', semantic_cfg.use_parallel));
    eval_s = toc(t_eval);
    fprintf('[MB][stage05-sem] h=%.0f km: Stage05 semantic truth finished in %.2fs.\n', h_km, eval_s);

    envelope_table = build_mb_stage05_semantic_envelope(eval_out.eval_table, h_km, semantic_cfg.i_grid_deg);
    frontier_summary = build_mb_stage05_semantic_transition_summary(eval_out.eval_table, envelope_table, h_km, semantic_cfg.i_grid_deg);

    height_runs(idx).h_km = h_km;
    height_runs(idx).design_table = design_table;
    height_runs(idx).eval_table = eval_out.eval_table;
    height_runs(idx).feasible_table = eval_out.feasible_table;
    height_runs(idx).envelope_table = envelope_table;
    height_runs(idx).frontier_summary = frontier_summary;
    height_runs(idx).summary = struct( ...
        'design_count', height(design_table), ...
        'feasible_count', height(eval_out.feasible_table), ...
        'minimum_feasible_Ns', eval_out.summary.minimum_feasible_Ns, ...
        'eval_s', eval_s);

    total_design_count = total_design_count + height(design_table);
    total_feasible_count = total_feasible_count + height(eval_out.feasible_table);
    total_eval_s = total_eval_s + eval_s;
end

out.cfg = semantic_cfg;
out.inputs = rmfield(semantic_inputs, {'cfg', 'trajs_nominal', 'hard_order', 'eval_context'});
out.height_runs = height_runs;
out.summary = struct( ...
    'enabled', true, ...
    'family_name', "nominal", ...
    'h_fixed_list', semantic_cfg.h_fixed_list, ...
    'i_grid_deg', semantic_cfg.i_grid_deg, ...
    'P_grid', semantic_cfg.P_grid, ...
    'T_grid', semantic_cfg.T_grid, ...
    'F_fixed', semantic_cfg.F_fixed, ...
    'gamma_req', semantic_inputs.gamma_req, ...
    'source_stage02_file', semantic_inputs.stage02_file, ...
    'source_stage04_file', semantic_inputs.stage04_file, ...
    'total_design_count', total_design_count, ...
    'total_feasible_count', total_feasible_count, ...
    'total_eval_s', total_eval_s, ...
    'interpretation_note', "This control branch reproduces the original Stage05 nominal-family semantics inside MB outputs: fixed-height coarse scans, Stage04-inherited gamma_req, and D_G-only pass-ratio / feasibility diagnostics. It is intended for apples-to-apples comparison against legacy Stage05 threshold figures, not for formal MB conclusions.");
end

function semantic_cfg = local_semantic_cfg(meta)
semantic_cfg = struct();
semantic_cfg.h_fixed_list = reshape(unique(meta.stage05_semantic_h_km(:), 'stable'), 1, []);
semantic_cfg.i_grid_deg = reshape(unique(meta.stage05_semantic_i_deg(:), 'stable'), 1, []);
semantic_cfg.P_grid = reshape(unique(meta.stage05_semantic_P(:), 'stable'), 1, []);
semantic_cfg.T_grid = reshape(unique(meta.stage05_semantic_T(:), 'stable'), 1, []);
semantic_cfg.F_fixed = meta.stage05_semantic_F;
semantic_cfg.use_parallel = local_getfield_or(meta, 'stage05_semantic_use_parallel', true);
semantic_cfg.force_rebuild_inputs = local_getfield_or(meta, 'stage05_semantic_force_rebuild_inputs', false);
end

function run = local_empty_height_run()
run = struct( ...
    'h_km', NaN, ...
    'design_table', table(), ...
    'eval_table', table(), ...
    'feasible_table', table(), ...
    'envelope_table', table(), ...
    'frontier_summary', table(), ...
    'summary', struct());
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
