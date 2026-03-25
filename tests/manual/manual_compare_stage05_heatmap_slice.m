function out = manual_compare_stage05_heatmap_slice()
startup;

% ---------------------------------
% Profile and config preparation
% ---------------------------------
profile = make_profile_MB_nominal_validation_stage05();

cfg_legacy = default_params();
cfg_legacy = stage09_prepare_cfg(cfg_legacy);
cfg_legacy = configure_stage_output_paths(cfg_legacy);

cfg_engine_profile = config_service(profile);
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
    legacy_rows(k).feasible_flag = legacy_eval.feasible_flag;
    legacy_rows(k).joint_margin = legacy_eval.joint_margin;

    engine_rows(k).design_id = string(row.design_id);
    engine_rows(k).h_km = row.h_km;
    engine_rows(k).i_deg = row.i_deg;
    engine_rows(k).P = row.P;
    engine_rows(k).T = row.T;
    engine_rows(k).F = row.F;
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
out.profile_name = string(profile.name);
out.gamma_eff_scalar = gamma_eff_scalar;
out.legacy_table = legacy_tbl;
out.engine_table = engine_tbl;
out.feasible_compare = feasible_compare;
out.margin_compare = margin_compare;

disp('[manual] Stage05 heatmap-slice comparison completed.');
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
