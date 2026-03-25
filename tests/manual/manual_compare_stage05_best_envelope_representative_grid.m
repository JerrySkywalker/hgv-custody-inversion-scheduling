function out = manual_compare_stage05_best_envelope_representative_grid()
startup;

profile = make_profile_MB_nominal_validation_stage05();

cfg_legacy = default_params();
cfg_legacy = stage09_prepare_cfg(cfg_legacy);
cfg_legacy = configure_stage_output_paths(cfg_legacy);

cfg_engine_profile = config_service(profile);
cfg_engine = local_merge_cfg_for_engine(cfg_legacy, cfg_engine_profile);

rows = manual_make_stage05_representative_grid();
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
    legacy_rows(k).DG_rob = legacy_eval.DG_rob;

    engine_rows(k).design_id = string(row.design_id);
    engine_rows(k).h_km = row.h_km;
    engine_rows(k).i_deg = row.i_deg;
    engine_rows(k).P = row.P;
    engine_rows(k).T = row.T;
    engine_rows(k).F = row.F;
    engine_rows(k).Ns = row.Ns;
    engine_rows(k).pass_ratio = engine_eval.pass_ratio;
    engine_rows(k).DG_rob = engine_eval.DG_rob;
end

legacy_tbl = struct2table(legacy_rows);
engine_tbl = struct2table(engine_rows);

legacy_env = build_best_envelope(legacy_tbl, 'Ns', 'pass_ratio', struct('i_deg', 60), 'max');
engine_env = build_best_envelope(engine_tbl, 'Ns', 'pass_ratio', struct('i_deg', 60), 'max');

legacy_env = renamevars(legacy_env, {'pass_ratio'}, {'legacy_best_pass'});
engine_env = renamevars(engine_env, {'pass_ratio'}, {'engine_best_pass'});

compare_tbl = innerjoin(legacy_env, engine_env, 'Keys', {'Ns'});
compare_tbl.best_pass_abs_diff = abs(compare_tbl.legacy_best_pass - compare_tbl.engine_best_pass);

if all(ismember({'best_geometry_margin_legacy_env','best_geometry_margin_engine_env'}, compare_tbl.Properties.VariableNames))
    compare_tbl.best_geometry_margin_abs_diff = abs( ...
        compare_tbl.best_geometry_margin_legacy_env - compare_tbl.best_geometry_margin_engine_env);
else
    compare_tbl.best_geometry_margin_abs_diff = NaN(height(compare_tbl),1);
end

out = struct();
out.legacy_env = legacy_env;
out.engine_env = engine_env;
out.compare_table = compare_tbl;

disp('[manual] Stage05 representative-grid best-pass envelope comparison completed.');
disp(compare_tbl);
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
