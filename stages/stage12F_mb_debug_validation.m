function out = stage12F_mb_debug_validation(cfg, overrides)
%STAGE12F_MB_DEBUG_VALIDATION Lightweight MB sanity checks for source merging and family switching.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

meta = cfg.milestones.MB;
task_meta = meta;
if isfield(meta, 'task_slice_settings') && isstruct(meta.task_slice_settings)
    task_meta.slice_settings = meta.task_slice_settings;
end
if isfield(overrides, 'meta') && isstruct(overrides.meta)
    meta = milestone_common_merge_structs(meta, overrides.meta);
end
if isfield(overrides, 'task_meta') && isstruct(overrides.task_meta)
    task_meta = milestone_common_merge_structs(task_meta, overrides.task_meta);
end

pool = stage12B_mb_design_pool(cfg, meta);
slice_hi = stage12C_inverse_slice_packager(pool, 'hi', meta);
slice_pt = stage12C_inverse_slice_packager(pool, 'PT', meta);
task_nominal = stage12D_task_slice_packager(pool, 'nominal', task_meta);
task_heading = stage12D_task_slice_packager(pool, 'heading', task_meta);
task_critical = stage12D_task_slice_packager(pool, 'critical', task_meta);

source_count_table = local_source_count_table({slice_hi, slice_pt, task_nominal, task_heading, task_critical});
family_config_table = local_family_config_table({task_nominal, task_heading, task_critical});
pool_summary_table = local_pool_summary_table(pool, {task_nominal, task_heading, task_critical});

debug_theta = cfg.milestones.baseline_theta;
if isfield(overrides, 'debug_theta') && isstruct(overrides.debug_theta)
    debug_theta = milestone_common_merge_structs(debug_theta, overrides.debug_theta);
end
family_design_table = local_family_design_table(cfg, debug_theta, task_meta);

paths = milestone_common_output_paths(cfg, 'MB', meta.title);
pool_csv = fullfile(paths.tables, 'MB_debug_pool_summary.csv');
source_csv = fullfile(paths.tables, 'MB_debug_source_counts.csv');
family_csv = fullfile(paths.tables, 'MB_debug_family_config.csv');
design_csv = fullfile(paths.tables, 'MB_debug_family_design_eval.csv');
writetable(pool_summary_table, pool_csv);
writetable(source_count_table, source_csv);
writetable(family_config_table, family_csv);
writetable(family_design_table, design_csv);

out = struct();
out.pool_summary_table = pool_summary_table;
out.source_count_table = source_count_table;
out.family_config_table = family_config_table;
out.family_design_table = family_design_table;
out.files = struct('pool_csv', string(pool_csv), 'source_csv', string(source_csv), 'family_csv', string(family_csv), 'design_csv', string(design_csv));
end

function T = local_source_count_table(results)
rows = cell(numel(results), 1);
for k = 1:numel(results)
    r = results{k};
    source_id = local_result_id(r);
    full_raw = r.full_theta_table;
    feasible_raw = r.feasible_theta_table;
    full_unique = unique_design_rows(full_raw);
    feasible_unique = unique_design_rows(feasible_raw);
    rows{k} = table(string(source_id), height(full_raw), height(full_unique), height(feasible_raw), height(feasible_unique), ...
        'VariableNames', {'source_id', 'num_full_raw', 'num_full_unique', 'num_feasible_raw', 'num_feasible_unique'});
end
T = vertcat(rows{:});
end

function T = local_family_config_table(results)
rows = cell(numel(results), 1);
for k = 1:numel(results)
    r = results{k};
    counts = local_count_case_families(build_stage09_casebank(r.cfg));
    rows{k} = table(string(r.task_slice_id), r.summary.casebank_size, ...
        counts.nominal, counts.heading, counts.critical, string(r.summary.config_signature), ...
        'VariableNames', {'family_name', 'casebank_size', 'nominal_cases', 'heading_cases', 'critical_cases', 'config_signature'});
end
T = vertcat(rows{:});
end

function T = local_pool_summary_table(pool, task_results)
minimum_pack = stage12E_minimum_design_packager(pool, pool.cfg, pool.meta);
rows = {
    "design_pool_total", height(pool.design_pool_table)
    "joint_feasible_total", height(pool.feasible_theta_table_joint)
    "minimum_design_count", height(minimum_pack.minimum_design_table)
    "near_optimal_region_size", height(minimum_pack.near_optimal_table)
    "slice_anchor_hi_P", pool.slice_anchor_hi.P
    "slice_anchor_hi_T", pool.slice_anchor_hi.T
    "slice_anchor_hi_F", pool.slice_anchor_hi.F
    "slice_anchor_pt_h_km", pool.slice_anchor_pt.h_km
    "slice_anchor_pt_i_deg", pool.slice_anchor_pt.i_deg
    "slice_anchor_pt_F", pool.slice_anchor_pt.F};

for k = 1:numel(task_results)
    r = task_results{k};
    rows(end + 1, :) = {sprintf('%s_feasible_total', char(string(r.task_slice_id))), r.summary.num_feasible}; %#ok<AGROW>
end

T = cell2table(rows, 'VariableNames', {'metric_name', 'metric_value'});
end

function T = local_family_design_table(cfg, debug_theta, task_meta)
families = {'nominal', 'heading', 'critical'};
rows = cell(numel(families), 1);
for k = 1:numel(families)
    family = families{k};
    cfg_stage = local_single_design_cfg(cfg, family, debug_theta, task_meta);
    trajs_in = build_stage09_casebank(cfg_stage);
    gamma_eff_scalar = 1.0;
    eval_ctx = build_stage09_eval_context(trajs_in, cfg_stage, gamma_eff_scalar);
    row = struct('h_km', debug_theta.h_km, 'i_deg', debug_theta.i_deg, 'P', debug_theta.P, 'T', debug_theta.T, ...
        'F', debug_theta.F, 'Ns', debug_theta.P * debug_theta.T);
    result = evaluate_single_layer_walker_stage09(row, trajs_in, gamma_eff_scalar, cfg_stage, eval_ctx);
    rows{k} = table(string(family), row.h_km, row.i_deg, row.P, row.T, row.F, row.Ns, ...
        result.DG_rob, result.DA_rob, result.DT_rob, result.joint_margin, result.feasible_flag, string(result.dominant_fail_tag), ...
        'VariableNames', {'family_name', 'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'DG_rob', 'DA_rob', 'DT_rob', 'joint_margin', 'feasible_flag', 'dominant_fail_tag'});
end
T = vertcat(rows{:});
end

function cfg_stage = local_single_design_cfg(cfg, family, debug_theta, task_meta)
cfg_stage = cfg;
cfg_stage = stage09_prepare_cfg(cfg_stage);
cfg_stage.stage09.scheme_type = 'custom';
cfg_stage.stage09.run_tag = sprintf('stage12F_%s', family);
cfg_stage.stage09.casebank_mode = 'custom';
cfg_stage.stage09.casebank_include_nominal = false;
cfg_stage.stage09.casebank_include_heading = false;
cfg_stage.stage09.casebank_include_critical = false;
cfg_stage.stage09.search_domain.h_grid_km = debug_theta.h_km;
cfg_stage.stage09.search_domain.i_grid_deg = debug_theta.i_deg;
cfg_stage.stage09.search_domain.P_grid = debug_theta.P;
cfg_stage.stage09.search_domain.T_grid = debug_theta.T;
cfg_stage.stage09.search_domain.F_fixed = debug_theta.F;

switch lower(family)
    case 'nominal'
        cfg_stage.stage09.casebank_include_nominal = true;
    case 'heading'
        cfg_stage.stage09.casebank_include_heading = true;
        if isfield(task_meta, 'slice_settings') && isfield(task_meta.slice_settings, 'heading_subset_max')
            cfg_stage.stage09.casebank_heading_subset_max = task_meta.slice_settings.heading_subset_max;
        end
    case 'critical'
        cfg_stage.stage09.casebank_include_critical = true;
end
end

function source_id = local_result_id(r)
if isfield(r, 'slice_name')
    source_id = r.slice_name;
elseif isfield(r, 'task_slice_id')
    source_id = r.task_slice_id;
else
    source_id = "unknown";
end
end

function counts = local_count_case_families(trajs_in)
counts = struct('nominal', 0, 'heading', 0, 'critical', 0);
if isempty(trajs_in)
    return;
end
for k = 1:numel(trajs_in)
    if isfield(trajs_in(k).case, 'family')
        family_name = lower(string(trajs_in(k).case.family));
        if isfield(counts, char(family_name))
            counts.(char(family_name)) = counts.(char(family_name)) + 1;
        end
    end
end
end
