function out = mb_vgeom_eval_case(case_ctx, design_pool_table, cfg_vgeom)
%MB_VGEOM_EVAL_CASE Evaluate one (h, i, Ns, semantic) vgeom case.

if nargin < 3 || isempty(cfg_vgeom)
    cfg_vgeom = struct();
end
if isempty(design_pool_table)
    error('mb_vgeom_eval_case requires a non-empty design_pool_table.');
end

max_designs = local_getfield_or(cfg_vgeom, 'max_designs_per_case', inf);
if isfinite(max_designs) && height(design_pool_table) > max_designs
    design_pool_table = design_pool_table(1:max_designs, :);
end

scene_eval_rows = cell(0, 1);
best_map = containers.Map('KeyType', 'char', 'ValueType', 'any');

for idx_design = 1:height(design_pool_table)
    design_row = design_pool_table(idx_design, :);
    scene_table = mb_vgeom_make_scene_grid(design_row, cfg_vgeom, false);
    for idx_scene = 1:height(scene_table)
        design_scene = mb_vgeom_apply_scene_to_design(case_ctx.cfg, design_row, scene_table(idx_scene, :));
        scene_eval = mb_vgeom_eval_design_scene(case_ctx, design_scene, case_ctx.semantic_mode);
        scene_eval_rows{end + 1, 1} = local_build_scene_design_row(case_ctx, design_scene, scene_eval); %#ok<AGROW>

        key = char(scene_eval.scene_id);
        if ~isKey(best_map, key)
            best_map(key) = scene_eval_rows{end};
        else
            current_best = best_map(key);
            candidate = scene_eval_rows{end};
            if local_is_better_candidate(candidate, current_best)
                best_map(key) = candidate;
            end
        end
    end
end

scene_design_eval_table = local_rows_to_table(scene_eval_rows);
scene_best_rows = values(best_map);
if isempty(scene_best_rows)
    scene_best_table = table();
else
    scene_best_table = local_rows_to_table(vertcat(scene_best_rows{:}));
    scene_best_table = sortrows(scene_best_table, {'phase_bin_idx', 'raan_bin_idx'});
end

scene_agg_row = local_build_agg_row(case_ctx, design_pool_table, scene_best_table);

out = struct();
out.scene_design_eval_table = scene_design_eval_table;
out.scene_best_table = scene_best_table;
out.scene_agg_row = scene_agg_row;
end

function row = local_build_scene_design_row(case_ctx, design_scene, scene_eval)
row = struct();
row.height_km = case_ctx.height_km;
row.inclination_deg = case_ctx.inclination_deg;
row.Ns = case_ctx.Ns;
row.semantic = string(case_ctx.semantic_mode);
row.scene_id = string(scene_eval.scene_id);
row.raan_bin_idx = double(design_scene.scene.raan_bin_idx);
row.phase_bin_idx = double(design_scene.scene.phase_bin_idx);
row.raan_offset_deg = double(scene_eval.raan_offset_deg);
row.phase_offset_norm = double(scene_eval.phase_offset_norm);
row.best_design_id = string(scene_eval.design_id);
row.best_num_planes = double(scene_eval.num_planes);
row.best_total_sats = double(scene_eval.total_sats);
row.best_pass_ratio = double(scene_eval.pass_ratio);
row.best_score = double(scene_eval.score);
row.best_feasible_flag = logical(scene_eval.feasible_flag);
row.num_cases = double(scene_eval.num_cases);
row.num_cases_evaluated = double(scene_eval.num_cases_evaluated);
row.failed_early = logical(scene_eval.failed_early);
row.raan_fundamental_deg = double(design_scene.scene.raan_fundamental_deg);
row.use_fundamental_domain = logical(design_scene.scene.use_fundamental_domain);
end

function tf = local_is_better_candidate(candidate, incumbent)
eps_val = 1e-12;
if candidate.best_pass_ratio > incumbent.best_pass_ratio + eps_val
    tf = true;
    return;
end
if candidate.best_pass_ratio < incumbent.best_pass_ratio - eps_val
    tf = false;
    return;
end
if candidate.best_score > incumbent.best_score + eps_val
    tf = true;
    return;
end
if candidate.best_score < incumbent.best_score - eps_val
    tf = false;
    return;
end
if candidate.best_num_planes > incumbent.best_num_planes
    tf = true;
    return;
end
if candidate.best_num_planes < incumbent.best_num_planes
    tf = false;
    return;
end
tf = local_string_lt(candidate.best_design_id, incumbent.best_design_id);
end

function T = local_rows_to_table(rows)
if isempty(rows)
    T = table();
    return;
end
if iscell(rows)
    rows = vertcat(rows{:});
end
T = struct2table(rows, 'AsArray', true);
end

function agg_row = local_build_agg_row(case_ctx, design_pool_table, scene_best_table)
quantiles = local_getfield_or(case_ctx.cfg_vgeom, 'stats_quantiles', [0.25, 0.5]);
pass_values = scene_best_table.best_pass_ratio;
pass_values = pass_values(isfinite(pass_values));
q25 = local_pick_quantile(pass_values, quantiles, 0.25);
median_v = local_pick_quantile(pass_values, quantiles, 0.50);
if isempty(pass_values)
    mean_v = NaN;
    min_v = NaN;
else
    mean_v = mean(pass_values, 'omitnan');
    min_v = min(pass_values, [], 'omitnan');
end

agg_row = struct();
agg_row.height_km = case_ctx.height_km;
agg_row.inclination_deg = case_ctx.inclination_deg;
agg_row.Ns = case_ctx.Ns;
agg_row.semantic = string(case_ctx.semantic_mode);
agg_row.num_designs = height(design_pool_table);
agg_row.num_scenes = height(scene_best_table);
agg_row.scene_best_mean = mean_v;
agg_row.scene_best_median = median_v;
agg_row.scene_best_q25 = q25;
agg_row.scene_best_min = min_v;
agg_row.scene_best_q25_envelope = NaN;
agg_row.scene_best_median_envelope = NaN;
agg_row.scene_best_mean_envelope = NaN;
agg_row.raan_bins = local_getfield_or(case_ctx.cfg_vgeom, 'raan_bins', 6);
agg_row.phase_bins = local_getfield_or(case_ctx.cfg_vgeom, 'phase_bins', 6);
agg_row.use_fundamental_domain = logical(local_getfield_or(case_ctx.cfg_vgeom, 'use_fundamental_domain', true));
end

function q = local_pick_quantile(values, quantiles, target)
q = NaN;
if isempty(values)
    return;
end
target_idx = find(abs(double(quantiles) - target) < 1e-9, 1, 'first');
if isempty(target_idx)
    q = quantile(values, target);
else
    q = quantile(values, quantiles(target_idx));
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function tf = local_string_lt(a, b)
s = sort(string([a, b]));
tf = strcmp(char(string(a)), char(s(1)));
end
