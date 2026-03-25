function out = manual_compare_stage05_opend_representative_grid()
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

% ------------------------------------------------------------
% Legacy truth path (keep explicit evaluator loop)
% ------------------------------------------------------------
n = numel(rows);
legacy_rows = repmat(struct(), n, 1);

for k = 1:n
    row = rows(k);

    legacy_eval = evaluate_single_layer_walker_stage09( ...
        row, task_family.trajs_in, gamma_eff_scalar, cfg_legacy);

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
end

legacy_tbl = struct2table(legacy_rows);
legacy_tbl = renamevars(legacy_tbl, ...
    {'pass_ratio','feasible_flag','DG_rob'}, ...
    {'legacy_pass_ratio','legacy_feasible_flag','legacy_geometry_margin'});

% ------------------------------------------------------------
% Framework search path (use unified search entry)
% ------------------------------------------------------------
search_spec = struct();
search_spec.gamma_eff_scalar = gamma_eff_scalar;
search_spec.run_tag = 'repgrid_compare';
search_spec.save_cache = false;
search_spec.show_progress = false;
search_spec.progress_every = 100;
search_spec.logger = struct( ...
    'enable_console', false, ...
    'console_level', 'INFO', ...
    'enable_file', false);

sr = run_design_grid_search(rows, task_family, 'opend', cfg_engine, search_spec);
engine_tbl = sr.grid_table(:, {'design_id','h_km','i_deg','P','T','F','Ns','pass_ratio','feasible_flag','DG_rob'});
engine_tbl = renamevars(engine_tbl, ...
    {'pass_ratio','feasible_flag','DG_rob'}, ...
    {'engine_pass_ratio','engine_feasible_flag','engine_geometry_margin'});

compare_tbl = innerjoin( ...
    legacy_tbl, engine_tbl, ...
    'Keys', {'design_id','h_km','i_deg','P','T','F','Ns'});

compare_tbl.pass_ratio_abs_diff = abs(compare_tbl.legacy_pass_ratio - compare_tbl.engine_pass_ratio);
compare_tbl.feasible_match = compare_tbl.legacy_feasible_flag == compare_tbl.engine_feasible_flag;
compare_tbl.geometry_margin_abs_diff = abs(compare_tbl.legacy_geometry_margin - compare_tbl.engine_geometry_margin);

out = struct();
out.profile_name = string(profile.name);
out.gamma_eff_scalar = gamma_eff_scalar;
out.legacy_table = legacy_tbl;
out.engine_table = engine_tbl;
out.compare_table = compare_tbl;

disp('[manual] Stage05 OpenD representative-grid comparison completed.');
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
