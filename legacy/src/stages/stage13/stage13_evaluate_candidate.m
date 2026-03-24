function out = stage13_evaluate_candidate(cfg, candidate, paths)
%STAGE13_EVALUATE_CANDIDATE Evaluate one Stage13 candidate via MA truth kernel.

cfg = stage13_default_config(cfg);
if istable(candidate)
    candidate = table2struct(candidate);
end

if isfield(candidate, 'case_mode') && strcmpi(string(candidate.case_mode), "custom")
    scan_out = local_eval_custom_case(cfg, candidate);
else
    overrides = local_build_overrides(candidate);
    scan_out = stage12B_truth_case_window_scan(cfg, overrides);
end
signature = stage13_extract_case_signature(scan_out, candidate);

curve_csv = fullfile(paths.cache, sprintf('stage13_curve_%s.csv', signature.case_tag));
writetable(scan_out.window_table, curve_csv);
signature.curve_data_path = string(curve_csv);

out = struct();
out.candidate = candidate;
out.scan_out = scan_out;
out.signature = signature;
end

function overrides = local_build_overrides(candidate)
overrides = struct();
overrides.case_mode = char(candidate.case_mode);
overrides.case_id = char(candidate.case_id);
overrides.Tw_s = candidate.Tw_s;
overrides.theta = struct( ...
    'h_km', candidate.h_km, ...
    'i_deg', candidate.i_deg, ...
    'P', candidate.P, ...
    'T', candidate.T, ...
    'F', candidate.F);
end

function out = local_eval_custom_case(cfg, candidate)
cfg_eval = stage09_prepare_cfg(cfg);
theta = struct( ...
    'h_km', candidate.h_km, ...
    'i_deg', candidate.i_deg, ...
    'P', candidate.P, ...
    'T', candidate.T, ...
    'F', candidate.F);
Tw_s = candidate.Tw_s;

cfg_eval.stage04.Tw_s = Tw_s;
cfg_eval.stage09.Tw_source = 'manual';
cfg_eval.stage09.Tw_manual_s = Tw_s;
cfg_eval.stage09.run_tag = 'stage13_custom_truth_case_window_scan';

selection = struct();
selection.case_id = string(candidate.case_struct.case_id);
selection.case_family = local_resolve_case_family(candidate.case_struct);
selection.case_index = NaN;
selection.case_exists = true;
selection.case_label = string(candidate.case_struct.case_id);
selection.case_struct = candidate.case_struct;

traj_case = local_build_custom_case(candidate.case_struct, cfg_eval);
cfg_eval.stage03.h_km = theta.h_km;
cfg_eval.stage03.i_deg = theta.i_deg;
cfg_eval.stage03.P = theta.P;
cfg_eval.stage03.T = theta.T;
cfg_eval.stage03.F = theta.F;
cfg_eval.stage09.gamma_eff_scalar = 1.0;

walker = build_single_layer_walker_stage03(cfg_eval);
satbank = propagate_constellation_stage03(walker, traj_case.traj.t_s);
vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_eval);
window_grid = build_window_grid_stage04(vis_case.t_s, cfg_eval);

nW = window_grid.num_windows;
DG_window = nan(nW, 1);
DA_window = nan(nW, 1);
DT_bar_window = nan(nW, 1);
DT_window = nan(nW, 1);
dt_max_window_s = nan(nW, 1);

for iw = 1:nW
    idx0 = window_grid.start_idx(iw);
    idx1 = window_grid.end_idx(iw);

    Wr = build_window_info_matrix_stage04(vis_case, idx0, idx1, satbank, cfg_eval);
    Wr = 0.5 * (Wr + Wr.');
    wm = compute_window_metrics_stage09(Wr, cfg_eval);
    gap = compute_gap_metrics_stage09(vis_case.t_s(idx0:idx1), vis_case.num_visible(idx0:idx1), cfg_eval);

    DG_window(iw) = wm.DG;
    DA_window(iw) = wm.DA;
    DT_bar_window(iw) = gap.DT_bar_window;
    DT_window(iw) = gap.DT_window;
    dt_max_window_s(iw) = gap.dt_max_window;
end

[~, idxG] = min(DG_window);
[~, idxA] = min(DA_window);
[~, idxT] = min(DT_window);

window_table = table( ...
    repmat(string(selection.case_id), nW, 1), ...
    window_grid.t0_s(:), DG_window, DA_window, DT_bar_window, DT_window, ...
    dt_max_window_s, ...
    false(nW, 1), false(nW, 1), false(nW, 1), ...
    'VariableNames', {'case_id', 't0_s', 'DG_window', 'DA_window', 'DT_bar_window', 'DT_window', ...
    'dt_max_window_s', 'DG_is_worst', 'DA_is_worst', 'DT_is_worst'});
window_table.DG_is_worst(idxG) = true;
window_table.DA_is_worst(idxA) = true;
window_table.DT_is_worst(idxT) = true;

summary_table = table( ...
    string(selection.case_id), string(selection.case_family), ...
    DG_window(idxG), DA_window(idxA), DT_bar_window(idxT), DT_window(idxT), ...
    window_grid.t0_s(idxG), window_grid.t0_s(idxA), window_grid.t0_s(idxT), dt_max_window_s(idxT), ...
    'VariableNames', {'case_id', 'case_family', ...
    'DG_worst_truth', 'DA_worst_truth', 'DT_bar_worst', 'DT_worst_truth', ...
    't0G_star_s', 't0A_star_s', 't0T_star_s', 'dt_max_at_t0T_star_s'});

out = struct();
out.cfg = cfg_eval;
out.overrides = struct('case_mode', 'custom', 'case_id', char(selection.case_id), 'Tw_s', Tw_s, 'theta', theta);
out.case_selection = selection;
out.theta_baseline = theta;
out.window_table = window_table;
out.summary_table = summary_table;
out.vis_case = vis_case;
out.window_grid = window_grid;
out.files = struct();
end

function traj_case = local_build_custom_case(case_i, cfg)
traj_case = struct();
traj_case.case = case_i;
traj_case.traj = propagate_hgv_case_stage02(case_i, cfg);
traj_case.validation = validate_hgv_trajectory_stage02(traj_case.traj, cfg);
traj_case.summary = summarize_hgv_case_stage02(case_i, traj_case.traj, traj_case.validation);
end

function case_family = local_resolve_case_family(case_struct)
if isfield(case_struct, 'family') && ~isempty(case_struct.family)
    case_family = string(case_struct.family);
elseif isfield(case_struct, 'subfamily') && ~isempty(case_struct.subfamily)
    case_family = string(case_struct.subfamily);
else
    case_family = "custom";
end
end
