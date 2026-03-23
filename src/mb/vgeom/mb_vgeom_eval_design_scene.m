function scene_eval = mb_vgeom_eval_design_scene(case_ctx, design_scene, semantic_mode)
%MB_VGEOM_EVAL_DESIGN_SCENE Re-evaluate one design under one geometry scene.

semantic_token = lower(strtrim(char(string(semantic_mode))));
switch semantic_token
    case 'legacydg'
        metrics = local_eval_stage05_scene(case_ctx, design_scene.walker);
        score_value = metrics.D_G_min;
    case 'closedd'
        metrics = local_eval_stage09_scene(case_ctx, design_scene.walker);
        score_value = metrics.joint_margin;
    otherwise
        error('Unsupported semantic_mode: %s', string(semantic_mode));
end

scene_eval = struct();
scene_eval.semantic_mode = string(semantic_mode);
scene_eval.design_id = design_scene.design_id;
scene_eval.scene_id = string(design_scene.scene.scene_id);
scene_eval.raan_offset_deg = double(design_scene.scene.raan_offset_deg);
scene_eval.phase_offset_norm = double(design_scene.scene.phase_offset_norm);
scene_eval.pass_ratio = double(metrics.pass_ratio);
scene_eval.score = double(score_value);
scene_eval.feasible_flag = logical(metrics.feasible_flag);
scene_eval.num_cases = double(metrics.n_case_total);
scene_eval.num_cases_evaluated = double(metrics.n_case_evaluated);
scene_eval.failed_early = logical(metrics.failed_early);
scene_eval.num_planes = double(design_scene.walker.P);
scene_eval.total_sats = double(design_scene.walker.Ns);
end

function metrics = local_eval_stage05_scene(case_ctx, walker)
cfg_eval = case_ctx.cfg;
cfg_eval.stage03.h_km = walker.h_km;
cfg_eval.stage03.i_deg = walker.i_deg;
cfg_eval.stage03.P = walker.P;
cfg_eval.stage03.T = walker.T;
cfg_eval.stage03.F = walker.F;
cfg_eval.stage04.gamma_req = case_ctx.gamma_req;

satbank = propagate_constellation_stage03(walker, case_ctx.t_s_common);
trajs_in = case_ctx.trajs_in;
hard_order = case_ctx.hard_order(:);
nCase = numel(trajs_in);

D_G = nan(nCase, 1);
pass_flag = false(nCase, 1);
n_evaluated = 0;
failed_early = false;

for kk = 1:nCase
    k = hard_order(kk);
    traj_case = trajs_in(k);

    vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_eval);
    window_case = scan_worst_window_stage04(vis_case, satbank, cfg_eval);
    s_win = summarize_window_case_stage04(window_case);

    D_G(k) = s_win.lambda_min_worst / case_ctx.gamma_req;
    pass_flag(k) = (D_G(k) >= cfg_eval.stage05.require_D_G_min);
    n_evaluated = n_evaluated + 1;

    if cfg_eval.stage05.use_early_stop && cfg_eval.stage05.require_pass_ratio >= 1.0 && ~pass_flag(k)
        failed_early = true;
        break;
    end
end

D_G_valid = D_G(isfinite(D_G));
pass_flag_valid = pass_flag(isfinite(D_G));
if isempty(D_G_valid)
    D_G_min = NaN;
    pass_ratio = NaN;
else
    D_G_min = min(D_G_valid);
    if failed_early
        pass_ratio = sum(pass_flag_valid) / nCase;
    else
        pass_ratio = mean(pass_flag_valid, 'omitnan');
    end
end

metrics = struct();
metrics.pass_ratio = pass_ratio;
metrics.D_G_min = D_G_min;
metrics.feasible_flag = (pass_ratio >= cfg_eval.stage05.require_pass_ratio) && ...
    (D_G_min >= cfg_eval.stage05.require_D_G_min);
metrics.n_case_total = nCase;
metrics.n_case_evaluated = n_evaluated;
metrics.failed_early = failed_early;
end

function metrics = local_eval_stage09_scene(case_ctx, walker)
eval_ctx = case_ctx.eval_ctx;
cfg_eval = eval_ctx.cfg;
cfg_eval.stage03.h_km = walker.h_km;
cfg_eval.stage03.i_deg = walker.i_deg;
cfg_eval.stage03.P = walker.P;
cfg_eval.stage03.T = walker.T;
cfg_eval.stage03.F = walker.F;
cfg_eval.stage09.gamma_eff_scalar = eval_ctx.gamma_eff_scalar;
if isfield(cfg_eval.stage09, 'Tw_star_s') && ~isempty(cfg_eval.stage09.Tw_star_s)
    cfg_eval.stage04.Tw_s = cfg_eval.stage09.Tw_star_s;
end

satbank = propagate_constellation_stage03(walker, eval_ctx.t_s_common);
trajs_in = case_ctx.trajs_in;
hard_order = case_ctx.hard_order(:);
nCase = eval_ctx.nCase;

case_id = eval_ctx.case_id;
family = eval_ctx.family;
subfamily = eval_ctx.subfamily;
entry_id = eval_ctx.entry_id;
heading_offset_deg = eval_ctx.heading_offset_deg;

DG_case = nan(nCase, 1);
DA_case = nan(nCase, 1);
DT_bar_case = nan(nCase, 1);
DT_case = nan(nCase, 1);
joint_case_margin = nan(nCase, 1);
pass_flag_case = false(nCase, 1);
lambda_worst = nan(nCase, 1);
sigma_A_proj_worst = nan(nCase, 1);
t0_worst_DG = nan(nCase, 1);
t0_worst_DA = nan(nCase, 1);
t0_worst_DT = nan(nCase, 1);
dt_max_s = nan(nCase, 1);
mean_vis = nan(nCase, 1);
dual_ratio = nan(nCase, 1);
custody_ratio = nan(nCase, 1);
fail_tag_case = strings(nCase, 1);

n_evaluated = 0;
failed_early = false;
for kk = 1:nCase
    k = hard_order(kk);
    traj_case = trajs_in(k);

    vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_eval);
    los_geom = compute_los_geometry_stage03(vis_case, satbank);
    s_vis = summarize_visibility_case_stage03(vis_case, los_geom);

    window_grid = build_window_grid_stage04(vis_case.t_s, cfg_eval);
    i0 = window_grid.start_idx(:);
    i1 = window_grid.end_idx(:);
    nW = window_grid.num_windows;

    DG_w = nan(nW, 1);
    DA_w = nan(nW, 1);
    lambda_min_w = nan(nW, 1);
    sigma_A_proj_w = nan(nW, 1);

    for iw = 1:nW
        Wr = build_window_info_matrix_stage04(vis_case, i0(iw), i1(iw), satbank, cfg_eval);
        Wr = 0.5 * (Wr + Wr.');
        wm = compute_window_metrics_stage09(Wr, cfg_eval);
        DG_w(iw) = wm.DG;
        DA_w(iw) = wm.DA;
        lambda_min_w(iw) = wm.lambda_min_eff;
        sigma_A_proj_w(iw) = wm.sigma_A_proj;
    end

    valid_metric_window = (DG_w > 0) | (DA_w > 0);
    if any(valid_metric_window)
        DG_w_eff = DG_w;
        DG_w_eff(~valid_metric_window) = inf;
        [DG_case(k), idx_DG] = min(DG_w_eff);

        DA_w_eff = DA_w;
        DA_w_eff(~valid_metric_window) = inf;
        [DA_case(k), idx_DA] = min(DA_w_eff);

        lambda_worst(k) = lambda_min_w(idx_DG);
        sigma_A_proj_worst(k) = sigma_A_proj_w(idx_DA);
        t0_worst_DG(k) = window_grid.t0_s(idx_DG);
        t0_worst_DA(k) = window_grid.t0_s(idx_DA);
    else
        DG_case(k) = 0;
        DA_case(k) = 0;
        lambda_worst(k) = 0;
        sigma_A_proj_worst(k) = inf;
        t0_worst_DG(k) = window_grid.t0_s(1);
        t0_worst_DA(k) = window_grid.t0_s(1);
    end

    gap = compute_gap_metrics_stage09(vis_case.t_s, vis_case.num_visible, cfg_eval);
    DT_bar_case(k) = gap.DT_bar_window;
    DT_case(k) = gap.DT_window;
    dt_max_s(k) = gap.dt_max_window;
    custody_ratio(k) = gap.custody_ratio;
    t0_worst_DT(k) = vis_case.t_s(1);

    joint_case_margin(k) = min([DG_case(k), DA_case(k), DT_case(k)]);
    pass_flag_case(k) = ...
        (DG_case(k) >= cfg_eval.stage09.require_DG_min) && ...
        (DA_case(k) >= cfg_eval.stage09.require_DA_min) && ...
        (DT_case(k) >= cfg_eval.stage09.require_DT_min);
    fail_tag_case(k) = local_case_fail_tag(DG_case(k), DA_case(k), DT_case(k), cfg_eval.stage09);
    mean_vis(k) = s_vis.mean_num_visible;
    dual_ratio(k) = s_vis.dual_coverage_ratio;
    n_evaluated = n_evaluated + 1;

    if cfg_eval.stage09.use_early_stop && cfg_eval.stage09.require_pass_ratio >= 1.0 && ~pass_flag_case(k)
        failed_early = true;
        break;
    end
end

case_table = table( ...
    case_id, family, subfamily, entry_id, heading_offset_deg, ...
    DG_case, DA_case, DT_bar_case, DT_case, joint_case_margin, pass_flag_case, ...
    lambda_worst, sigma_A_proj_worst, t0_worst_DG, t0_worst_DA, t0_worst_DT, ...
    dt_max_s, mean_vis, dual_ratio, custody_ratio, fail_tag_case, ...
    'VariableNames', { ...
        'case_id', 'family', 'subfamily', 'entry_id', 'heading_offset_deg', ...
        'DG', 'DA', 'DT_bar', 'DT', 'joint_case_margin', 'pass_flag_case', ...
        'lambda_worst', 'sigma_A_proj_worst', 't0_worst_DG_s', 't0_worst_DA_s', 't0_worst_DT_s', ...
        'dt_max_s', 'mean_num_visible', 'dual_coverage_ratio', 'custody_ratio', 'fail_tag_case'});

row = struct( ...
    'h_km', walker.h_km, ...
    'i_deg', walker.i_deg, ...
    'P', walker.P, ...
    'T', walker.T, ...
    'F', walker.F, ...
    'Ns', walker.Ns);
agg = aggregate_stage09_case_table(case_table, row, cfg_eval, failed_early, nCase, n_evaluated);

metrics = struct();
metrics.pass_ratio = agg.pass_ratio;
metrics.joint_margin = agg.joint_margin;
metrics.feasible_flag = logical(agg.feasible_flag);
metrics.n_case_total = agg.n_case_total;
metrics.n_case_evaluated = agg.n_case_evaluated;
metrics.failed_early = logical(agg.failed_early);
end

function tag = local_case_fail_tag(DG, DA, DT, s9)
g = DG < s9.require_DG_min;
a = DA < s9.require_DA_min;
t = DT < s9.require_DT_min;
if ~(g || a || t)
    tag = "OK";
    return;
end
parts = strings(0, 1);
if g
    parts(end + 1, 1) = "G";
end
if a
    parts(end + 1, 1) = "A";
end
if t
    parts(end + 1, 1) = "T";
end
tag = join(parts, "");
tag = string(tag);
end
