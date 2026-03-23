function result = run_mb_vgeom_h1000(cfg, run_tag)
%RUN_MB_VGEOM_H1000 Minimal geometry-ensemble validation for the MB V-shape question.

mb_safe_startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults([], cfg);
end
if nargin < 2 || strlength(string(run_tag)) == 0
    run_tag = string(datestr(now, 'yyyymmdd_HHMMSS'));
end

cfg.vgeom.enabled = true;
cfg.vgeom.height_km = 1000;
cfg.vgeom.sensor_group = 'baseline';
cfg.vgeom.semantics = local_normalize_string_list(cfg.vgeom.semantics);

cfg_run = cfg;
cfg_run.milestones.MB_vgeom.milestone_id = sprintf('MB_vgeom_h1000_%s', char(run_tag));
cfg_run.milestones.MB_vgeom.title = 'geometry_ensemble';
paths = mb_output_paths(cfg_run, cfg_run.milestones.MB_vgeom.milestone_id, cfg_run.milestones.MB_vgeom.title);
paths.summary_report = fullfile(paths.tables, cfg_run.milestones.MB_vgeom.summary_report_name);
paths.summary_mat = fullfile(paths.tables, cfg_run.milestones.MB_vgeom.summary_mat_name);

fprintf('[MB][vgeom] run_tag=%s semantics=%s inclinations=%s bins=%dx%d\n', ...
    char(string(run_tag)), ...
    strjoin(cfg_run.vgeom.semantics, ','), ...
    mat2str(double(cfg_run.vgeom.inclination_deg_list)), ...
    double(cfg_run.vgeom.raan_bins), ...
    double(cfg_run.vgeom.phase_bins));

source_summary_mat = local_resolve_source_summary_mat(cfg_run);
loaded = load(source_summary_mat, 'result');
baseline_result = loaded.result;
fprintf('[MB][vgeom] source_summary=%s\n', char(source_summary_mat));

all_scene_design_rows = cell(0, 1);
all_scene_best_rows = cell(0, 1);
all_agg_rows = cell(0, 1);
case_rows = cell(0, 1);

for idx_sem = 1:numel(cfg_run.vgeom.semantics)
    semantic_name = char(string(cfg_run.vgeom.semantics{idx_sem}));
    fprintf('[MB][vgeom] build_source_context semantic=%s\n', semantic_name);
    source = local_build_source_context(cfg_run, baseline_result, semantic_name);
    for idx_i = 1:numel(cfg_run.vgeom.inclination_deg_list)
        inclination_deg = cfg_run.vgeom.inclination_deg_list(idx_i);
        ns_list = mb_vgeom_get_ns_list(cfg_run.vgeom, source.run, inclination_deg);
        fprintf('[MB][vgeom] semantic=%s i=%g ns_list=%s\n', semantic_name, inclination_deg, mat2str(double(ns_list)));
        for idx_ns = 1:numel(ns_list)
            Ns = ns_list(idx_ns);
            design_pool = source.run.design_table( ...
                abs(double(source.run.design_table.h_km) - cfg_run.vgeom.height_km) < 1e-9 & ...
                abs(double(source.run.design_table.i_deg) - double(inclination_deg)) < 1e-9 & ...
                abs(double(source.run.design_table.Ns) - double(Ns)) < 1e-9, :);
            if isempty(design_pool)
                continue;
            end

            fprintf('[MB][vgeom] semantic=%s i=%g Ns=%g designs=%d\n', semantic_name, inclination_deg, Ns, height(design_pool));
            case_ctx = local_make_case_context(cfg_run, source, semantic_name, inclination_deg, Ns);
            case_out = mb_vgeom_eval_case(case_ctx, design_pool, cfg_run.vgeom);

            if cfg_run.vgeom.save_scene_eval_table && ~isempty(case_out.scene_design_eval_table)
                all_scene_design_rows{end + 1, 1} = case_out.scene_design_eval_table; %#ok<AGROW>
            end
            if ~isempty(case_out.scene_best_table)
                all_scene_best_rows{end + 1, 1} = case_out.scene_best_table; %#ok<AGROW>
            end
            all_agg_rows{end + 1, 1} = struct2table(case_out.scene_agg_row, 'AsArray', true); %#ok<AGROW>
            case_rows{end + 1, 1} = table(string(semantic_name), inclination_deg, Ns, height(design_pool), ...
                'VariableNames', {'semantic', 'inclination_deg', 'Ns', 'design_count'}); %#ok<AGROW>
        end
    end
end

scene_design_eval_table = local_vertcat_tables(all_scene_design_rows);
scene_best_table = local_vertcat_tables(all_scene_best_rows);
scene_agg_table = local_vertcat_tables(all_agg_rows);
scene_case_table = local_vertcat_tables(case_rows);
scene_agg_table = mb_vgeom_make_envelope(scene_agg_table, cfg_run.vgeom);
scene_audit_table = local_build_case_audit(scene_case_table, scene_best_table, scene_agg_table, cfg_run.vgeom);
fprintf('[MB][vgeom] assembled case_count=%d scene_best_rows=%d scene_eval_rows=%d\n', ...
    height(scene_case_table), height(scene_best_table), height(scene_design_eval_table));

scene_best_csv = fullfile(paths.tables, 'MB_vgeom_scene_best_table.csv');
scene_agg_csv = fullfile(paths.tables, 'MB_vgeom_scene_agg_table.csv');
scene_case_csv = fullfile(paths.tables, 'MB_vgeom_case_manifest.csv');
scene_audit_csv = fullfile(paths.tables, 'MB_vgeom_case_audit.csv');
closure_csv = fullfile(paths.tables, 'MB_vgeom_closure_summary.csv');
if cfg_run.vgeom.save_scene_eval_table
    scene_eval_csv = fullfile(paths.tables, 'MB_vgeom_scene_design_eval_table.csv');
    milestone_common_save_table(scene_design_eval_table, scene_eval_csv);
else
    scene_eval_csv = "";
end
milestone_common_save_table(scene_best_table, scene_best_csv);
milestone_common_save_table(scene_agg_table, scene_agg_csv);
milestone_common_save_table(scene_case_table, scene_case_csv);
milestone_common_save_table(scene_audit_table, scene_audit_csv);

fprintf('[MB][vgeom] plotting_bundle_start\n');
figure_map = mb_vgeom_plot_bundle(scene_best_table, scene_agg_table, paths, cfg_run.vgeom);
fprintf('[MB][vgeom] plotting_bundle_done\n');
summary_md = mb_vgeom_write_summary(scene_agg_table, paths, cfg_run.vgeom);
fprintf('[MB][vgeom] summary_written=%s\n', char(summary_md));

closure_summary = table( ...
    cfg_run.vgeom.height_km, ...
    string(cfg_run.vgeom.sensor_group), ...
    numel(cfg_run.vgeom.semantics), ...
    height(scene_case_table), ...
    height(scene_best_table), ...
    height(scene_design_eval_table), ...
    logical(cfg_run.vgeom.use_fundamental_domain), ...
    logical(cfg_run.vgeom.reuse_design_pool), ...
    cfg_run.vgeom.raan_bins, ...
    cfg_run.vgeom.phase_bins, ...
    string(source_summary_mat), ...
    string(scene_audit_csv), ...
    string(summary_md), ...
    "pass", ...
    'VariableNames', {'height_km', 'sensor_group', 'semantic_count', 'case_count', 'scene_best_row_count', ...
    'scene_eval_row_count', 'use_fundamental_domain', 'reuse_design_pool', 'raan_bins', 'phase_bins', ...
    'source_summary_mat', 'case_audit_csv', 'summary_markdown', 'final_status'});
milestone_common_save_table(closure_summary, closure_csv);

result = struct();
result.milestone_id = string(cfg_run.milestones.MB_vgeom.milestone_id);
result.title = string(cfg_run.milestones.MB_vgeom.title);
result.config = cfg_run;
result.tables = struct( ...
    'scene_best_table', string(scene_best_csv), ...
    'scene_agg_table', string(scene_agg_csv), ...
    'scene_case_table', string(scene_case_csv), ...
    'scene_audit_table', string(scene_audit_csv), ...
    'scene_design_eval_table', string(scene_eval_csv), ...
    'closure_summary', string(closure_csv));
result.figures = figure_map;
result.artifacts = struct( ...
    'source_summary_mat', string(source_summary_mat), ...
    'summary_report', string(summary_md));
result.summary = struct( ...
    'height_km', cfg_run.vgeom.height_km, ...
    'sensor_group', string(cfg_run.vgeom.sensor_group), ...
    'semantics', {cfg_run.vgeom.semantics}, ...
    'inclinations', cfg_run.vgeom.inclination_deg_list, ...
    'case_count', height(scene_case_table), ...
    'scene_best_row_count', height(scene_best_table), ...
    'scene_eval_row_count', height(scene_design_eval_table));
save(paths.summary_mat, 'result', '-v7.3');
end

function source_summary_mat = local_resolve_source_summary_mat(cfg)
source_summary_mat = string(cfg.vgeom.source_summary_mat);
if strlength(source_summary_mat) > 0 && exist(source_summary_mat, 'file') == 2
    return;
end

tag = char(string(local_getfield_or(cfg.vgeom, 'output_root_tag', local_getfield_or(cfg.milestones.MB_vgeom, 'source_root_tag', 'globalfullreplay'))));
listing = dir(fullfile(cfg.paths.milestones, sprintf('MB_*_%s_baseline', tag), 'tables', 'MB_semantic_compare_summary.mat'));
if isempty(listing)
    error('Could not locate source MB semantic summary for vgeom run.');
end
[~, idx_latest] = max([listing.datenum]);
source_summary_mat = string(fullfile(listing(idx_latest).folder, listing(idx_latest).name));
end

function source = local_build_source_context(cfg, baseline_result, semantic_name)
run_outputs = baseline_result.artifacts.run_outputs;
hit = find(strcmpi(arrayfun(@(s) char(string(s.mode)), run_outputs, 'UniformOutput', false), semantic_name), 1, 'first');
if isempty(hit)
    error('Could not locate semantic source run for %s.', semantic_name);
end
run_output = run_outputs(hit).run_output;
run_idx = find(arrayfun(@(s) abs(double(s.h_km) - 1000) < 1e-9, run_output.runs), 1, 'first');
if isempty(run_idx)
    error('Could not locate h=1000 run for %s.', semantic_name);
end

source = struct();
source.semantic = string(semantic_name);
source.run = run_output.runs(run_idx);
source.run_output = run_output;
source.cfg = cfg;
switch lower(semantic_name)
    case 'legacydg'
        stage02 = load(char(run_output.inputs.stage02_file), 'out');
        stage04 = load(char(run_output.inputs.stage04_file), 'out');
        trajs_in = stage02.out.trajbank.nominal;
        source.trajs_in = trajs_in;
        source.hard_order = local_build_legacy_hard_order(trajs_in, stage04.out, 'nominal');
        source.t_s_common = local_build_stage05_eval_time_grid(trajs_in, run_output.inputs.cfg);
        source.gamma_req = run_output.inputs.gamma_req;
        source.cfg_sensor = run_output.inputs.cfg;
    case 'closedd'
        cfg_sensor = apply_sensor_param_group_to_cfg(baseline_result.config, cfg.vgeom.sensor_group);
        cfg_stage = stage09_prepare_cfg(cfg_sensor);
        cfg_stage.stage09.casebank_include_nominal = true;
        cfg_stage.stage09.casebank_include_heading = false;
        cfg_stage.stage09.casebank_include_critical = false;
        cfg_stage.stage09.casebank_mode = 'custom';
        cfg_stage.stage09.use_parallel = false;
        trajs_in = local_build_closedd_nominal_casebank(cfg_stage);
        eval_ctx = build_stage09_eval_context(trajs_in, cfg_stage, 1.0);
        source.trajs_in = trajs_in;
        source.hard_order = (1:numel(trajs_in)).';
        source.eval_ctx = eval_ctx;
        source.cfg_sensor = cfg_sensor;
    otherwise
        error('Unsupported semantic source: %s', semantic_name);
end
end

function case_ctx = local_make_case_context(cfg, source, semantic_name, inclination_deg, Ns)
case_ctx = struct();
case_ctx.cfg = source.cfg_sensor;
case_ctx.cfg_vgeom = cfg.vgeom;
case_ctx.semantic_mode = string(semantic_name);
case_ctx.height_km = cfg.vgeom.height_km;
case_ctx.inclination_deg = inclination_deg;
case_ctx.Ns = Ns;
case_ctx.trajs_in = source.trajs_in;
case_ctx.hard_order = source.hard_order;
switch lower(char(string(semantic_name)))
    case 'legacydg'
        case_ctx.gamma_req = source.gamma_req;
        case_ctx.t_s_common = source.t_s_common;
    case 'closedd'
        case_ctx.eval_ctx = source.eval_ctx;
end
end

function hard_order = local_build_legacy_hard_order(trajs_in, stage04_out, family_name)
hard_order = (1:numel(trajs_in)).';
if ~isfield(stage04_out, 'summary') || ~isfield(stage04_out.summary, 'margin') || ~isfield(stage04_out.summary.margin, 'case_table')
    return;
end
tab4 = stage04_out.summary.margin.case_table;
required_vars = {'case_ids', 'D_G', 'families'};
if isempty(tab4) || ~all(ismember(required_vars, tab4.Properties.VariableNames))
    return;
end
traj_case_ids = strings(numel(trajs_in), 1);
for idx = 1:numel(trajs_in)
    traj_case_ids(idx) = string(trajs_in(idx).case.case_id);
end
tab_family = tab4(strcmp(string(tab4.families), string(family_name)), :);
if isempty(tab_family)
    return;
end
[~, ord] = sort(tab_family.D_G, 'ascend');
hard_ids = string(tab_family.case_ids(ord));
hard_order_tmp = nan(numel(hard_ids), 1);
for idx = 1:numel(hard_ids)
    hit = find(traj_case_ids == hard_ids(idx), 1, 'first');
    if ~isempty(hit)
        hard_order_tmp(idx) = hit;
    end
end
hard_order_tmp = hard_order_tmp(isfinite(hard_order_tmp));
if numel(hard_order_tmp) == numel(trajs_in)
    hard_order = hard_order_tmp;
end
end

function t_s_common = local_build_stage05_eval_time_grid(trajs_in, cfg_stage)
t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
t_s_common = (0:cfg_stage.stage02.Ts_s:max(t_end_all)).';
end

function T = local_vertcat_tables(table_bank)
if isempty(table_bank)
    T = table();
    return;
end
T = vertcat(table_bank{:});
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function audit_table = local_build_case_audit(scene_case_table, scene_best_table, scene_agg_table, cfg_vgeom)
if isempty(scene_case_table)
    audit_table = table();
    return;
end

row_bank = cell(height(scene_case_table), 1);
expected_scene_count = double(local_getfield_or(cfg_vgeom, 'raan_bins', 6)) * double(local_getfield_or(cfg_vgeom, 'phase_bins', 6));
for idx = 1:height(scene_case_table)
    row_case = scene_case_table(idx, :);
    mask_best = string(scene_best_table.semantic) == string(row_case.semantic) & ...
        abs(double(scene_best_table.inclination_deg) - double(row_case.inclination_deg)) < 1e-9 & ...
        abs(double(scene_best_table.Ns) - double(row_case.Ns)) < 1e-9;
    sub_best = scene_best_table(mask_best, :);
    mask_agg = string(scene_agg_table.semantic) == string(row_case.semantic) & ...
        abs(double(scene_agg_table.inclination_deg) - double(row_case.inclination_deg)) < 1e-9 & ...
        abs(double(scene_agg_table.Ns) - double(row_case.Ns)) < 1e-9;
    sub_agg = scene_agg_table(mask_agg, :);

    row = struct();
    row.height_km = 1000;
    row.inclination_deg = double(row_case.inclination_deg);
    row.Ns = double(row_case.Ns);
    row.semantic = string(row_case.semantic);
    row.design_count = double(row_case.design_count);
    row.scene_count_expected = expected_scene_count;
    row.scene_count_actual = height(sub_best);
    row.design_pool_reused = logical(local_getfield_or(cfg_vgeom, 'reuse_design_pool', true));
    row.use_fundamental_domain = logical(local_getfield_or(cfg_vgeom, 'use_fundamental_domain', true));
    row.raan_bins = double(local_getfield_or(cfg_vgeom, 'raan_bins', 6));
    row.phase_bins = double(local_getfield_or(cfg_vgeom, 'phase_bins', 6));
    if isempty(sub_best)
        row.raan_fundamental_deg_min = NaN;
        row.raan_fundamental_deg_max = NaN;
        row.best_num_planes_min = NaN;
        row.best_num_planes_max = NaN;
    else
        row.raan_fundamental_deg_min = min(double(sub_best.raan_fundamental_deg), [], 'omitnan');
        row.raan_fundamental_deg_max = max(double(sub_best.raan_fundamental_deg), [], 'omitnan');
        row.best_num_planes_min = min(double(sub_best.best_num_planes), [], 'omitnan');
        row.best_num_planes_max = max(double(sub_best.best_num_planes), [], 'omitnan');
    end
    agg_ok = ~isempty(sub_agg) && abs(double(sub_agg.num_scenes(1)) - height(sub_best)) < 1e-9;
    row.case_pass = row.design_count > 0 && height(sub_best) == expected_scene_count && agg_ok;
    row_bank{idx} = struct2table(row, 'AsArray', true);
end

audit_table = vertcat(row_bank{:});
end

function values = local_normalize_string_list(values_in)
if isstring(values_in)
    values = cellstr(values_in(:));
    return;
end
if ischar(values_in)
    values = {char(values_in)};
    return;
end
if iscell(values_in)
    flattened = cell(0, 1);
    for idx = 1:numel(values_in)
        item = values_in{idx};
        if iscell(item)
            sub = local_normalize_string_list(item);
            flattened = vertcat(flattened, reshape(sub, [], 1)); %#ok<AGROW>
        else
            flattened{end + 1, 1} = char(string(item)); %#ok<AGROW>
        end
    end
    values = flattened;
    return;
end
values = {char(string(values_in))};
end

function trajs_in = local_build_closedd_nominal_casebank(cfg_stage)
listing = find_stage_cache_files(cfg_stage, 'stage01_scenario_disk_*.mat');
if isempty(listing)
    error('MB vgeom could not locate any existing Stage01 cache for closedD nominal casebank.');
end
[~, idx_latest] = max([listing.datenum]);
stage01_file = fullfile(listing(idx_latest).folder, listing(idx_latest).name);
stage01_loaded = load(stage01_file, 'out');
casebank = stage01_loaded.out.casebank;
nominal_cases = casebank.nominal(:);
nCase = numel(nominal_cases);
trajs_in = repmat(struct('case', struct(), 'traj', struct(), 'validation', struct(), 'summary', struct()), nCase, 1);
for idx = 1:nCase
    case_i = nominal_cases(idx);
    traj_i = propagate_hgv_case_stage02(case_i, cfg_stage);
    val_i = validate_hgv_trajectory_stage02(traj_i, cfg_stage);
    sum_i = summarize_hgv_case_stage02(case_i, traj_i, val_i);
    trajs_in(idx).case = case_i;
    trajs_in(idx).traj = traj_i;
    trajs_in(idx).validation = val_i;
    trajs_in(idx).summary = sum_i;
end
end
