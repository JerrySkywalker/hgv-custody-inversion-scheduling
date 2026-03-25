function out = manual_compare_stage05_heatmap_representative_grid()
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
    legacy_rows(k).P = row.P;
    legacy_rows(k).T = row.T;
    legacy_rows(k).Ns = row.Ns;
    legacy_rows(k).feasible_flag = legacy_eval.feasible_flag;
    legacy_rows(k).joint_margin = legacy_eval.joint_margin;

    engine_rows(k).design_id = string(row.design_id);
    engine_rows(k).P = row.P;
    engine_rows(k).T = row.T;
    engine_rows(k).Ns = row.Ns;
    engine_rows(k).feasible_flag = engine_eval.feasible_flag;
    engine_rows(k).joint_margin = engine_eval.joint_margin;
end

legacy_tbl = struct2table(legacy_rows);
engine_tbl = struct2table(engine_rows);

legacy_feasible = legacy_tbl(:, {'design_id','P','T','Ns','feasible_flag'});
engine_feasible = engine_tbl(:, {'design_id','P','T','Ns','feasible_flag'});

legacy_feasible = renamevars(legacy_feasible, {'feasible_flag'}, {'legacy_feasible_flag'});
engine_feasible = renamevars(engine_feasible, {'feasible_flag'}, {'engine_feasible_flag'});

feasible_compare = innerjoin(legacy_feasible, engine_feasible, ...
    'Keys', {'design_id','P','T','Ns'});
feasible_compare.feasible_match = feasible_compare.legacy_feasible_flag == feasible_compare.engine_feasible_flag;

legacy_margin = legacy_tbl(:, {'design_id','P','T','Ns','joint_margin'});
engine_margin = engine_tbl(:, {'design_id','P','T','Ns','joint_margin'});

legacy_margin = renamevars(legacy_margin, {'joint_margin'}, {'legacy_joint_margin'});
engine_margin = renamevars(engine_margin, {'joint_margin'}, {'engine_joint_margin'});

margin_compare = innerjoin(legacy_margin, engine_margin, ...
    'Keys', {'design_id','P','T','Ns'});
margin_compare.joint_margin_abs_diff = abs(margin_compare.legacy_joint_margin - margin_compare.engine_joint_margin);

out = struct();
out.feasible_compare = feasible_compare;
out.margin_compare = margin_compare;

disp('[manual] Stage05 representative-grid heatmap comparison completed.');
disp(feasible_compare);
disp(margin_compare);
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
