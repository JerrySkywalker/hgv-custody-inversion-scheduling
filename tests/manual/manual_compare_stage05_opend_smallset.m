function out = manual_compare_stage05_opend_smallset()
startup;

% ---------------------------------
% Profile and config preparation
% ---------------------------------
profile = make_profile_MB_nominal_validation_stage05();

% Full legacy-style baseline cfg
cfg_legacy = default_params();
cfg_legacy = stage09_prepare_cfg(cfg_legacy);
cfg_legacy = configure_stage_output_paths(cfg_legacy);

% Framework experiment cfg (slim)
cfg_engine_profile = config_service(profile);

% Engine manual-regression cfg:
% start from full baseline, then overlay the profile-level experimental settings
cfg_engine = local_merge_cfg_for_engine(cfg_legacy, cfg_engine_profile);

design_pool = design_pool_service(cfg_engine);
rows = local_extract_design_rows(design_pool);

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
    row = local_complete_design_row(rows(k), cfg_engine, cfg_legacy);

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
    legacy_rows(k).h_km = row.h_km;
    legacy_rows(k).i_deg = row.i_deg;
    legacy_rows(k).P = row.P;
    legacy_rows(k).T = row.T;
    legacy_rows(k).F = row.F;
    legacy_rows(k).Ns = row.Ns;
    legacy_rows(k).pass_ratio = legacy_eval.pass_ratio;
    legacy_rows(k).feasible_flag = legacy_eval.feasible_flag;
    legacy_rows(k).joint_margin = legacy_eval.joint_margin;

    engine_rows(k).design_id = string(row.design_id);
    engine_rows(k).h_km = row.h_km;
    engine_rows(k).i_deg = row.i_deg;
    engine_rows(k).P = row.P;
    engine_rows(k).T = row.T;
    engine_rows(k).F = row.F;
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
    'Keys', {'design_id','h_km','i_deg','P','T','F','Ns'});

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

function cfg_out = local_merge_cfg_for_engine(cfg_base, cfg_overlay)
cfg_out = cfg_base;

overlay_fields = fieldnames(cfg_overlay);
for i = 1:numel(overlay_fields)
    f = overlay_fields{i};
    cfg_out.(f) = cfg_overlay.(f);
end

% Ensure the profile-level runtime / stage03 style settings are reflected
if isfield(cfg_overlay, 'runtime')
    cfg_out.runtime = cfg_overlay.runtime;
end

% Carry through explicit stage03-like design defaults when available
if isfield(cfg_overlay, 'stage03')
    cfg_out.stage03 = cfg_overlay.stage03;
end
end

function rows = local_extract_design_rows(design_pool)
if isstruct(design_pool) && isfield(design_pool, 'rows')
    rows = design_pool.rows;
elseif isstruct(design_pool) && isfield(design_pool, 'design_table')
    rows = design_pool.design_table;
elseif istable(design_pool)
    rows = table2struct(design_pool);
elseif isstruct(design_pool)
    fn = fieldnames(design_pool);
    if any(strcmp(fn, 'P')) || any(strcmp(fn, 'T')) || any(strcmp(fn, 'design_id'))
        rows = design_pool;
    else
        error('Unsupported design_pool container struct. Fields: %s', strjoin(fn, ', '));
    end
else
    error('Unsupported design_pool type: %s', class(design_pool));
end

if istable(rows)
    rows = table2struct(rows);
end
end

function row = local_complete_design_row(row, cfg_engine, cfg_legacy)
if ~isfield(row, 'P')
    error('Design row is missing field P.');
end

if ~isfield(row, 'T')
    error('Design row is missing field T.');
end

if ~isfield(row, 'h_km')
    if isfield(cfg_engine, 'stage03') && isfield(cfg_engine.stage03, 'h_km')
        row.h_km = cfg_engine.stage03.h_km;
    elseif isfield(cfg_legacy, 'stage03') && isfield(cfg_legacy.stage03, 'h_km')
        row.h_km = cfg_legacy.stage03.h_km;
    else
        row.h_km = 1000;
    end
end

if ~isfield(row, 'i_deg')
    if isfield(cfg_engine, 'stage03') && isfield(cfg_engine.stage03, 'i_deg')
        row.i_deg = cfg_engine.stage03.i_deg;
    elseif isfield(cfg_legacy, 'stage03') && isfield(cfg_legacy.stage03, 'i_deg')
        row.i_deg = cfg_legacy.stage03.i_deg;
    else
        row.i_deg = 60;
    end
end

if ~isfield(row, 'F')
    if isfield(cfg_engine, 'stage03') && isfield(cfg_engine.stage03, 'F')
        row.F = cfg_engine.stage03.F;
    elseif isfield(cfg_legacy, 'stage03') && isfield(cfg_legacy.stage03, 'F')
        row.F = cfg_legacy.stage03.F;
    else
        row.F = 0;
    end
end

if ~isfield(row, 'Ns')
    row.Ns = row.P * row.T;
end
end
