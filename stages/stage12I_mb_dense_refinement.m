function out = stage12I_mb_dense_refinement(cfg, pool, minimum_design_table, task_slice_summary, overrides)
%STAGE12I_MB_DENSE_REFINEMENT Run local dense zoom diagnostics around the formal MB minimum neighborhood.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(pool) || ~isstruct(pool)
    error('stage12I_mb_dense_refinement requires cfg and a populated pool.');
end
if nargin < 3 || isempty(minimum_design_table)
    minimum_design_table = table();
end
if nargin < 4 || isempty(task_slice_summary)
    task_slice_summary = table();
end
if nargin < 5 || isempty(overrides)
    overrides = struct();
end

meta = cfg.milestones.MB;
if isstruct(overrides)
    meta = milestone_common_merge_structs(meta, overrides);
end

out = struct();
out.summary = struct('enabled', false);
zoom_enabled = false;
if isfield(meta, 'enable_local_dense_zoom')
    zoom_enabled = logical(meta.enable_local_dense_zoom);
elseif isfield(meta, 'dense_refinement_enabled')
    zoom_enabled = logical(meta.dense_refinement_enabled);
end
if ~zoom_enabled
    return;
end

dense_cfg = local_dense_cfg(meta, pool, minimum_design_table);
fprintf('[MB][zoom] requirement grid: %d h x %d i x %d P x %d T.\n', ...
    numel(dense_cfg.requirement_h_km), numel(dense_cfg.requirement_i_deg), ...
    numel(dense_cfg.requirement_P), numel(dense_cfg.requirement_T));

t_requirement = tic;
requirement_design_table = local_build_requirement_design_table(dense_cfg);
requirement_eval = evaluate_dense_design_grid_with_stage09(cfg, requirement_design_table, struct( ...
    'family_names', ["joint", "nominal", "heading"], ...
    'heading_subset_max', dense_cfg.heading_subset_max, ...
    'use_parallel', true));
t_requirement_s = toc(t_requirement);
fprintf('[MB][zoom] requirement/gap local truth finished: %d designs in %.2fs.\n', ...
    height(requirement_design_table), t_requirement_s);

t_phasecurve = tic;
phasecurve_design_table = local_build_phasecurve_design_table(dense_cfg);
phasecurve_eval = evaluate_dense_design_grid_with_stage09(cfg, phasecurve_design_table, struct( ...
    'family_names', ["joint", "heading"], ...
    'heading_subset_max', dense_cfg.heading_subset_max, ...
    'use_parallel', true));
t_phasecurve_s = toc(t_phasecurve);
fprintf('[MB][zoom] phasecurve local truth finished: %d designs in %.2fs.\n', ...
    height(phasecurve_design_table), t_phasecurve_s);

out.cfg = dense_cfg;
out.minimum_design_table = minimum_design_table;
out.task_slice_summary = task_slice_summary;
out.requirement_design_table = requirement_design_table;
out.requirement_eval = requirement_eval;
out.requirement_surface_iP = build_dense_requirement_surface_iP(requirement_eval.joint.full_theta_table);
if dense_cfg.include_hi
    out.requirement_surface_hi = build_mb_requirement_surface(requirement_eval.joint.full_theta_table, 'i_deg', 'h_km');
else
    out.requirement_surface_hi = struct();
end
out.gap_surface_heading_minus_nominal = build_dense_gap_surface_iP( ...
    requirement_eval.heading.full_theta_table, requirement_eval.nominal.full_theta_table, 'heading', 'nominal');

out.phasecurve_design_table = phasecurve_design_table;
out.phasecurve_eval = phasecurve_eval;
out.phasecurve_joint = build_dense_passratio_phasecurve(phasecurve_eval.joint.full_theta_table, dense_cfg.phasecurve_i_deg);
out.phasecurve_heading = build_dense_passratio_phasecurve(phasecurve_eval.heading.full_theta_table, dense_cfg.phasecurve_i_deg);

out.summary = struct( ...
    'enabled', true, ...
    'baseline_F', dense_cfg.F, ...
    'formal_minimum_shell_Ns', local_first_value(minimum_design_table, 'Ns'), ...
    'zoom_candidate_minimum_Ns_joint', local_min_or_nan(requirement_eval.joint.feasible_theta_table, 'Ns'), ...
    'requirement_design_count', height(requirement_design_table), ...
    'phasecurve_design_count', height(phasecurve_design_table), ...
    'zoom_requirement_i_deg', dense_cfg.requirement_i_deg, ...
    'zoom_requirement_P', dense_cfg.requirement_P, ...
    'zoom_requirement_h_km', dense_cfg.requirement_h_km, ...
    'zoom_requirement_T', dense_cfg.requirement_T, ...
    'zoom_phasecurve_i_deg', dense_cfg.phasecurve_i_deg, ...
    'zoom_phasecurve_P', dense_cfg.phasecurve_P, ...
    'zoom_phasecurve_T', dense_cfg.phasecurve_T, ...
    'zoom_include_hi', dense_cfg.include_hi, ...
    'requirement_eval_s', t_requirement_s, ...
    'phasecurve_eval_s', t_phasecurve_s, ...
    'requirement_feasible_count', height(requirement_eval.joint.feasible_theta_table), ...
    'phasecurve_feasible_count_joint', height(phasecurve_eval.joint.feasible_theta_table), ...
    'phasecurve_feasible_count_heading', height(phasecurve_eval.heading.feasible_theta_table), ...
    'note', "These local zoom figures come from a locally expanded design domain around the formal MB shell. Any lower-N_s candidates discovered here should be interpreted as finer-grained feasible candidates inside the zoomed neighborhood, not as replacements for the formal full-MB minimum-shell definition.");
end

function dense_cfg = local_dense_cfg(meta, pool, minimum_design_table)
dense_cfg = struct();
dense_cfg.include_hi = isfield(meta, 'dense_include_hi') && logical(meta.dense_include_hi);
dense_cfg.heading_subset_max = meta.slice_settings.heading_subset_max;
dense_cfg.F = pool.baseline_theta.F;
dense_cfg.requirement_h_km = unique([meta.dense_requirement_h_km(:); local_column_or_empty(minimum_design_table, 'h_km')], 'sorted').';
dense_cfg.requirement_i_deg = unique([meta.dense_requirement_i_deg(:); local_column_or_empty(minimum_design_table, 'i_deg')], 'sorted').';
dense_cfg.requirement_P = unique([meta.dense_requirement_P(:); local_column_or_empty(minimum_design_table, 'P')], 'sorted').';
dense_cfg.requirement_T = unique(meta.dense_requirement_T(:), 'sorted').';
dense_cfg.phasecurve_h_km = unique(meta.dense_phasecurve_h_km(:), 'sorted').';
dense_cfg.phasecurve_i_deg = unique([meta.dense_phasecurve_i_deg(:); local_column_or_empty(minimum_design_table, 'i_deg')], 'sorted').';
dense_cfg.phasecurve_P = unique(meta.dense_phasecurve_P(:), 'sorted').';
dense_cfg.phasecurve_T = unique(meta.dense_phasecurve_T(:), 'sorted').';
end

function T = local_build_requirement_design_table(dense_cfg)
[H, I, P, TT] = ndgrid(dense_cfg.requirement_h_km, dense_cfg.requirement_i_deg, dense_cfg.requirement_P, dense_cfg.requirement_T);
n = numel(H);
T = table(H(:), I(:), P(:), TT(:), repmat(dense_cfg.F, n, 1), P(:) .* TT(:), repmat("dense_requirement", n, 1), ...
    'VariableNames', {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'slice_source'});
T = unique_design_rows(T);
T = sortrows(T, {'Ns', 'h_km', 'i_deg', 'P', 'T'}, {'ascend', 'ascend', 'ascend', 'ascend', 'ascend'});
end

function T = local_build_phasecurve_design_table(dense_cfg)
[H, I, P, TT] = ndgrid(dense_cfg.phasecurve_h_km, dense_cfg.phasecurve_i_deg, dense_cfg.phasecurve_P, dense_cfg.phasecurve_T);
n = numel(H);
T = table(H(:), I(:), P(:), TT(:), repmat(dense_cfg.F, n, 1), P(:) .* TT(:), repmat("dense_phasecurve", n, 1), ...
    'VariableNames', {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'slice_source'});
T = unique_design_rows(T);
T = sortrows(T, {'Ns', 'h_km', 'i_deg', 'P', 'T'}, {'ascend', 'ascend', 'ascend', 'ascend', 'ascend'});
end

function values = local_column_or_empty(T, field_name)
values = [];
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
values = T.(field_name);
end

function value = local_first_value(T, field_name)
value = NaN;
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
value = T.(field_name)(1);
end

function value = local_min_or_nan(T, field_name)
value = NaN;
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
value = min(T.(field_name), [], 'omitnan');
end
