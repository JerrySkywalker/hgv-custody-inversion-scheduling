function out = manual_compare_stage05_opend_fullgrid_all_i()
startup;

profile = make_profile_MB_nominal_validation_stage05();

cfg_legacy = default_params();
cfg_legacy = stage09_prepare_cfg(cfg_legacy);
cfg_legacy = configure_stage_output_paths(cfg_legacy);

cfg_engine_profile = config_service(profile);
cfg_engine = local_merge_cfg_for_engine(cfg_legacy, cfg_engine_profile);

rows = manual_make_stage05_fullgrid_all_i();
task_family = task_family_service(cfg_engine);

if isfield(profile, 'gamma_eff_scalar')
    gamma_eff_scalar = profile.gamma_eff_scalar;
else
    gamma_info = load_stage04_nominal_gamma_req();
    gamma_eff_scalar = gamma_info.gamma_req;
end

n = numel(rows);
legacy_rows = repmat(struct(), n, 1);
engine_rows = repmat(struct(), n, 1);

for k = 1:n
    row = rows(k);

    legacy_eval = evaluate_single_layer_walker_stage09( ...
        row, task_family.trajs_in, gamma_eff_scalar, cfg_legacy);

    engine_eval = evaluate_design_point_opend( ...
        row, task_family.trajs_in, gamma_eff_scalar, cfg_engine);

    legacy_rows(k).design_id = string(row.design_id);
    legacy_rows(k).h_km = row.h_km;
    legacy_rows(k).i_deg = row.i_deg;
    legacy_rows(k).P = row.P;
    legacy_rows(k).T = row.T;
    legacy_rows(k).F = row.F;
    legacy_rows(k).Ns = row.Ns;
    legacy_rows(k).pass_ratio = legacy_eval.pass_ratio;
    legacy_rows(k).feasible_flag = legacy_eval.feasible_flag;
    legacy_rows(k).DG_rob = legacy_eval.DG_rob;

    engine_rows(k).design_id = string(row.design_id);
    engine_rows(k).h_km = row.h_km;
    engine_rows(k).i_deg = row.i_deg;
    engine_rows(k).P = row.P;
    engine_rows(k).T = row.T;
    engine_rows(k).F = row.F;
    engine_rows(k).Ns = row.Ns;
    engine_rows(k).pass_ratio = engine_eval.pass_ratio;
    engine_rows(k).feasible_flag = engine_eval.feasible_flag;
    engine_rows(k).DG_rob = engine_eval.DG_rob;
end

legacy_tbl = struct2table(legacy_rows);
engine_tbl = struct2table(engine_rows);

legacy_tbl = renamevars(legacy_tbl, ...
    {'pass_ratio','feasible_flag','DG_rob'}, ...
    {'legacy_pass_ratio','legacy_feasible_flag','legacy_geometry_margin'});

engine_tbl = renamevars(engine_tbl, ...
    {'pass_ratio','feasible_flag','DG_rob'}, ...
    {'engine_pass_ratio','engine_feasible_flag','engine_geometry_margin'});

compare_tbl = innerjoin( ...
    legacy_tbl, engine_tbl, ...
    'Keys', {'design_id','h_km','i_deg','P','T','F','Ns'});

compare_tbl.pass_ratio_abs_diff = abs(compare_tbl.legacy_pass_ratio - compare_tbl.engine_pass_ratio);
compare_tbl.feasible_match = compare_tbl.legacy_feasible_flag == compare_tbl.engine_feasible_flag;
compare_tbl.geometry_margin_abs_diff = abs(compare_tbl.legacy_geometry_margin - compare_tbl.engine_geometry_margin);

% Summary by inclination
i_vals = unique(compare_tbl.i_deg);
summary_rows = repmat(struct(), numel(i_vals), 1);
for k = 1:numel(i_vals)
    ii = i_vals(k);
    sub = compare_tbl(compare_tbl.i_deg == ii, :);

    summary_rows(k).i_deg = ii;
    summary_rows(k).n_rows = height(sub);
    summary_rows(k).max_pass_ratio_abs_diff = max(sub.pass_ratio_abs_diff);
    summary_rows(k).all_feasible_match = all(sub.feasible_match);
    summary_rows(k).max_geometry_margin_abs_diff = max(sub.geometry_margin_abs_diff);
end
summary_tbl = struct2table(summary_rows);

out = struct();
out.profile_name = string(profile.name);
out.gamma_eff_scalar = gamma_eff_scalar;
out.legacy_table = legacy_tbl;
out.engine_table = engine_tbl;
out.compare_table = compare_tbl;
out.summary_table = summary_tbl;

disp('[manual] Stage05 OpenD full-grid all-i comparison completed.');
disp(summary_tbl);
end

function cfg_out = local_merge_cfg_for_engine(cfg_base, cfg_overlay)
cfg_out = cfg_base;
overlay_fields = fieldnames(cfg_overlay);
for i = 1:numel(overlay_fields)
    f = overlay_fields{i};
    cfg_out.(f) = cfg_overlay.(f);
end
if isfield(cfg_overlay, 'runtime')
    cfg_out.runtime = cfg_overlay.runtime;
end
if isfield(cfg_overlay, 'stage03')
    cfg_out.stage03 = cfg_overlay.stage03;
end
end
