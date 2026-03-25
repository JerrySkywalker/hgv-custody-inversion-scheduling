function out = manual_compare_stage05_opend_smallset()
startup;

% ---------------------------------
% Framework-side profile / cfg
% ---------------------------------
profile = make_profile_MB_nominal_validation_stage05();
cfg_engine = config_service(profile);

design_pool = design_pool_service(cfg_engine);

if isstruct(design_pool) && isfield(design_pool, 'rows')
    rows = design_pool.rows;
elseif istable(design_pool)
    rows = table2struct(design_pool);
elseif isstruct(design_pool)
    rows = design_pool;
else
    error('Unsupported design_pool type: %s', class(design_pool));
end

task_family = task_family_service(cfg_engine);

if isfield(profile, 'gamma_eff_scalar')
    gamma_eff_scalar = profile.gamma_eff_scalar;
else
    gamma_info = load_stage04_nominal_gamma_req();
    gamma_eff_scalar = gamma_info.gamma_req;
end

% ---------------------------------
% Legacy-side cfg for truth evaluator
% ---------------------------------
cfg_legacy = default_params();
cfg_legacy = stage09_prepare_cfg(cfg_legacy);
cfg_legacy = configure_stage_output_paths(cfg_legacy);

n = numel(rows);
legacy_rows = repmat(struct(), n, 1);
engine_rows = repmat(struct(), n, 1);

for k = 1:n
    row = rows(k);

    % ---------------------------
    % Legacy / current truth path
    % ---------------------------
    legacy_eval = evaluate_single_layer_walker_stage09( ...
        row, task_family.trajs_in, gamma_eff_scalar, cfg_legacy);

    % ---------------------------
    % Engine OpenD path
    % ---------------------------
    engine_eval = evaluate_design_point_opend( ...
        row, task_family.trajs_in, gamma_eff_scalar, cfg_engine);

    legacy_rows(k).design_id = string(row.design_id);
    legacy_rows(k).P = row.P;
    legacy_rows(k).T = row.T;
    legacy_rows(k).Ns = row.Ns;
    legacy_rows(k).pass_ratio = legacy_eval.pass_ratio;
    legacy_rows(k).feasible_flag = legacy_eval.feasible_flag;
    legacy_rows(k).joint_margin = legacy_eval.joint_margin;

    engine_rows(k).design_id = string(row.design_id);
    engine_rows(k).P = row.P;
    engine_rows(k).T = row.T;
    engine_rows(k).Ns = row.Ns;
    engine_rows(k).pass_ratio = engine_eval.pass_ratio;
    engine_rows(k).feasible_flag = engine_eval.feasible_flag;
    engine_rows(k).joint_margin = engine_eval.joint_margin;
end

legacy_tbl = struct2table(legacy_rows);
engine_tbl = struct2table(engine_rows);

legacy_tbl = renamevars(legacy_tbl, ...
    {'pass_ratio','feasible_flag','joint_margin'}, ...
    {'legacy_pass_ratio','legacy_feasible_flag','legacy_joint_margin'});

engine_tbl = renamevars(engine_tbl, ...
    {'pass_ratio','feasible_flag','joint_margin'}, ...
    {'engine_pass_ratio','engine_feasible_flag','engine_joint_margin'});

compare_tbl = innerjoin( ...
    legacy_tbl, engine_tbl, ...
    'Keys', {'design_id','P','T','Ns'});

compare_tbl.pass_ratio_abs_diff = abs(compare_tbl.legacy_pass_ratio - compare_tbl.engine_pass_ratio);
compare_tbl.feasible_match = compare_tbl.legacy_feasible_flag == compare_tbl.engine_feasible_flag;
compare_tbl.joint_margin_abs_diff = abs(compare_tbl.legacy_joint_margin - compare_tbl.engine_joint_margin);

out = struct();
out.profile_name = string(profile.name);
out.gamma_eff_scalar = gamma_eff_scalar;
out.legacy_table = legacy_tbl;
out.engine_table = engine_tbl;
out.compare_table = compare_tbl;

disp('[manual] Stage05 OpenD small-set comparison completed.');
disp(compare_tbl);
end
